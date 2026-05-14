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
    private let balanceReader: (any VaultBalanceReader)?
    private let historyReader: (any VaultHistoryReader)?
    private let tokenBalanceReader: (any TokenBalanceReader)?
    private let transactor: (any VaultTransactor)?

    private(set) var vaultBalance: Decimal?
    private(set) var splBalance: Decimal?
    private(set) var transactions: [VaultTransaction]?
    private(set) var isLoading = false
    private(set) var loadError: WalletError?
    private(set) var historyError: WalletError?
    private(set) var isTransacting = false
    private(set) var transactionError: WalletError?

    init(
        owner: Pubkey,
        balanceReader: (any VaultBalanceReader)?,
        historyReader: (any VaultHistoryReader)?,
        tokenBalanceReader: (any TokenBalanceReader)?,
        transactor: (any VaultTransactor)?
    ) {
        self.owner = owner
        self.balanceReader = balanceReader
        self.historyReader = historyReader
        self.tokenBalanceReader = tokenBalanceReader
        self.transactor = transactor
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil
        historyError = nil
        defer { isLoading = false }

        async let balance: Void = loadVaultBalance()
        async let history: Void = loadVaultHistory()
        async let spl: Void = loadSPLBalance()
        _ = await (balance, history, spl)
    }

    private func loadVaultBalance() async {
        guard let balanceReader else { return }
        do {
            vaultBalance = try await balanceReader.fetchVaultBalance(for: owner)
        } catch let WalletError.staleVaultCache(cached, underlying) {
            vaultBalance = cached
            loadError = underlying
        } catch let error as WalletError {
            loadError = error
        } catch {
            loadError = .unknown(underlying: "\(error)")
        }
    }

    private func loadSPLBalance() async {
        guard let tokenBalanceReader else { return }
        do {
            splBalance = try await tokenBalanceReader.fetchTokenBalance(for: owner, mint: VLT.mint)
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

    @discardableResult
    func deposit(amount: Decimal) async -> Bool {
        await runVaultTransaction { transactor in
            try await transactor.depositVault(owner: owner, amount: amount)
        }
    }

    @discardableResult
    func withdraw(amount: Decimal) async -> Bool {
        await runVaultTransaction { transactor in
            try await transactor.withdrawVault(owner: owner, amount: amount)
        }
    }

    private func runVaultTransaction(
        _ submit: @MainActor (any VaultTransactor) async throws -> TransactionSignature
    ) async -> Bool {
        guard let transactor, !isTransacting else { return false }
        isTransacting = true
        transactionError = nil
        defer { isTransacting = false }

        do {
            _ = try await submit(transactor)
            await load()
            return true
        } catch let error as WalletError {
            transactionError = error
            return false
        } catch {
            transactionError = .unknown(underlying: "\(error)")
            return false
        }
    }
}
