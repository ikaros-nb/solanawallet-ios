//
//  DashboardViewModel.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let owner: Pubkey
    private let vaultBalanceReader: (any VaultBalanceReader)?
    private let walletReader: (any WalletReader)?

    private(set) var solBalance: Lamports?
    private(set) var tokens: [SPLTokenAccount] = []
    private(set) var vaultBalance: Decimal?
    private(set) var isLoading = false
    private(set) var loadError: WalletError?

    init(
        owner: Pubkey,
        vaultBalanceReader: (any VaultBalanceReader)?,
        walletReader: (any WalletReader)?
    ) {
        self.owner = owner
        self.vaultBalanceReader = vaultBalanceReader
        self.walletReader = walletReader
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        async let balance: Void = loadBalance()
        async let tokenList: Void = loadTokens()
        async let vault: Void = loadVaultBalance()
        _ = await (balance, tokenList, vault)
    }

    private func loadBalance() async {
        guard let walletReader else { return }
        do {
            solBalance = try await walletReader.fetchBalance(for: owner)
        } catch let WalletError.staleCache(cached, underlying) {
            solBalance = cached
            loadError = underlying
        } catch let error as WalletError {
            loadError = error
        } catch {
            loadError = .unknown(underlying: "\(error)")
        }
    }

    private func loadTokens() async {
        guard let walletReader else { return }
        do {
            tokens = try await walletReader.fetchTokenAccounts(for: owner)
        } catch let WalletError.staleTokenCache(cached, underlying) {
            tokens = cached
            loadError = underlying
        } catch let error as WalletError {
            loadError = error
        } catch {
            loadError = .unknown(underlying: "\(error)")
        }
    }

    private func loadVaultBalance() async {
        guard let vaultBalanceReader else { return }
        do {
            vaultBalance = try await vaultBalanceReader.fetchVaultBalance(for: owner)
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
