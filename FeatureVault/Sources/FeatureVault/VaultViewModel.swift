//
//  VaultViewModel.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation

@Observable
@MainActor
final class VaultViewModel {
    private let owner: Pubkey
    private let vaultReader: (any VaultReader)?

    private(set) var vaultBalance: Decimal?
    private(set) var isLoading = false
    private(set) var loadError: WalletError?

    init(owner: Pubkey, vaultReader: (any VaultReader)?) {
        self.owner = owner
        self.vaultReader = vaultReader
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        await loadVaultBalance()
    }

    private func loadVaultBalance() async {
        guard let vaultReader else { return }
        do {
            vaultBalance = try await vaultReader.fetchVaultBalance(for: owner)
        } catch let WalletError.staleVaultCache(cached, underlying) {
            vaultBalance = cached
            loadError = underlying
        } catch let error as WalletError {
            loadError = error
        } catch {
            loadError = .unknown(underlying: "\(error)")
        }
    }
}
