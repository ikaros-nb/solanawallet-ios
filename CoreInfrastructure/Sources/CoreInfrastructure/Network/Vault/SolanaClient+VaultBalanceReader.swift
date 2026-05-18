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
            tokenAccountPDA = try VaultProgram.tokenAccountPDA(for: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        do {
            let balance = try await rpc.getTokenAccountBalance(
                pubkey: tokenAccountPDA.base58EncodedString,
                commitment: nil
            )
            let decimal = try VaultAmount.decode(balance)
            vaultBalanceCache[owner] = decimal
            return decimal
        } catch let APIClientError.responseError(response) where Self.isAccountNotFound(response) {
            vaultBalanceCache[owner] = 0
            return 0
        } catch APIClientError.couldNotRetrieveAccountInfo {
            vaultBalanceCache[owner] = 0
            return 0
        } catch {
            throw mapToStaleCacheError(error, cached: vaultBalanceCache[owner]) {
                .staleVaultCache($0, underlying: $1)
            }
        }
    }

    private static func isAccountNotFound(_ response: ResponseError) -> Bool {
        if response.code == -32602 { return true }
        return response.message?.localizedCaseInsensitiveContains("could not find account") == true
    }
}
