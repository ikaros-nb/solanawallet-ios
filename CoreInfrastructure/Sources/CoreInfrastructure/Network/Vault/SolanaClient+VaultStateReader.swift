//
//  SolanaClient+VaultStateReader.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

extension SolanaClient: VaultStateReader {
    public func fetchVaultExists(for owner: Pubkey) async throws -> Bool {
        let pda: PublicKey
        do {
            pda = try VaultProgram.statePDA(for: owner)
        } catch {
            throw WalletError.vaultError(code: 0, message: "PDA derivation failed: \(error)")
        }

        // getAccountInfo in solana-swift hardcodes the request configuration and
        // never passes a commitment, so the RPC defaults to "finalized" — which
        // lags behind the "confirmed" level the rest of our reads use. That
        // means a vault we just initialized via submitInstruction (which
        // returns at "confirmed") is invisible here for ~13s. getMultipleAccounts
        // takes commitment explicitly, so we pin it to SolanaCommitment.default.
        do {
            let infos: [BufferInfo<EmptyInfo>?] = try await rpc.getMultipleAccounts(
                pubkeys: [pda.base58EncodedString],
                commitment: SolanaCommitment.default
            )
            guard let maybeInfo = infos.first, let info = maybeInfo else { return false }
            return info.owner == VaultProgram.id
        } catch let apiError as APIClientError where apiError == .couldNotRetrieveAccountInfo {
            return false
        } catch {
            throw mapToWalletError(error)
        }
    }
}
