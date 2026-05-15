//
//  SolanaClient+VaultBalanceReader.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient: VaultBalanceReader {
    public func fetchVaultBalance(for owner: Pubkey) async throws -> Decimal {
        let tokenAccountPDA: PublicKey
        do {
            tokenAccountPDA = try VaultPDA.vaultTokenAccount(for: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        do {
            let balance = try await rpc.getTokenAccountBalance(
                pubkey: tokenAccountPDA.base58EncodedString,
                commitment: nil
            )
            let decimal = try Self.decode(tokenAccountBalance: balance)
            vaultBalanceCache[owner] = decimal
            return decimal
        } catch let APIClientError.responseError(response) where Self.isAccountNotFound(response) {
            vaultBalanceCache[owner] = 0
            return 0
        } catch APIClientError.couldNotRetrieveAccountInfo {
            vaultBalanceCache[owner] = 0
            return 0
        } catch {
            let mapped = mapToWalletError(error)
            if let cached = vaultBalanceCache[owner] {
                throw WalletError.staleVaultCache(cached, underlying: mapped)
            }
            throw mapped
        }
    }

    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func decode(tokenAccountBalance balance: TokenAccountBalance) throws -> Decimal {
        let uiDecimal = balance.uiAmountString.flatMap { Decimal(string: $0, locale: posix) }
        if let decimal = uiDecimal { return decimal }
        guard let rawAmount = UInt64(balance.amount), let decimals = balance.decimals else {
            throw WalletError.vaultError(code: 0, message: "invalid token account balance response")
        }
        return Decimal(rawAmount) / pow(10, Int(decimals))
    }

    private static func isAccountNotFound(_ response: ResponseError) -> Bool {
        if response.code == -32602 { return true }
        return response.message?.localizedCaseInsensitiveContains("could not find account") == true
    }
}
