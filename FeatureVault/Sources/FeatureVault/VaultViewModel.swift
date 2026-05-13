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
    private let historyReader: (any VaultHistoryReader)?

    private(set) var vaultBalance: Decimal?
    private(set) var transactions: [VaultTransaction]?
    private(set) var isLoading = false
    private(set) var loadError: WalletError?
    private(set) var historyError: WalletError?

    init(
        owner: Pubkey,
        vaultReader: (any VaultReader)?,
        historyReader: (any VaultHistoryReader)?
    ) {
        self.owner = owner
        self.vaultReader = vaultReader
        self.historyReader = historyReader
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        historyError = nil
        defer { isLoading = false }

        async let balance: Void = loadVaultBalance()
        async let history: Void = loadVaultHistory()
        _ = await (balance, history)
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

    private func loadVaultHistory() async {
        guard let historyReader else { return }
        do {
            transactions = try await historyReader.fetchVaultTransactions(for: owner, limit: 20)
        } catch let WalletError.staleVaultHistoryCache(cached, underlying) {
            transactions = cached
            historyError = underlying
        } catch let error as WalletError {
            historyError = error
        } catch {
            historyError = .unknown(underlying: "\(error)")
        }
    }
}
