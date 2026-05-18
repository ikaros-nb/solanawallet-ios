//
//  DashboardViewModel.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreDomain
import CoreEntities
import CoreUI
import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let owner: Pubkey
    private let vaultBalanceReader: (any VaultBalanceReader)?
    private let walletReader: (any WalletReader)?
    private let transactionSender: (any TransactionSender)?
    private let toastCenter: ToastCenter

    private(set) var solBalance: Lamports?
    private(set) var tokens: [SPLTokenAccount] = []
    private(set) var vaultBalance: Decimal?
    private(set) var isLoading = false
    private(set) var loadError: WalletError?
    private(set) var isTransacting = false
    private(set) var transactionError: WalletError?

    var solBalanceDecimal: Decimal? {
        solBalance.map { Decimal($0) / Decimal(SOL.lamportsPerSOL) }
    }

    init(
        owner: Pubkey,
        vaultBalanceReader: (any VaultBalanceReader)?,
        walletReader: (any WalletReader)?,
        transactionSender: (any TransactionSender)?,
        toastCenter: ToastCenter
    ) {
        self.owner = owner
        self.vaultBalanceReader = vaultBalanceReader
        self.walletReader = walletReader
        self.transactionSender = transactionSender
        self.toastCenter = toastCenter
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

        if loadError != nil {
            toastCenter.show(.error(.Dashboard.loadFailure))
        }
    }

    @discardableResult
    func send(amount: Decimal, to recipient: Pubkey) async -> Bool {
        guard let transactionSender, !isTransacting else { return false }
        isTransacting = true
        transactionError = nil
        defer { isTransacting = false }

        let lamports = NSDecimalNumber(decimal: amount * Decimal(SOL.lamportsPerSOL)).uint64Value
        do {
            _ = try await transactionSender.sendSOL(from: owner, to: recipient, amount: lamports)
            await load()
            toastCenter.show(.success(.Dashboard.sendSuccess))
            return true
        } catch let error as WalletError {
            transactionError = error
            toastCenter.show(.error(failureMessage(for: error)))
            return false
        } catch {
            transactionError = .unknown(underlying: "\(error)")
            toastCenter.show(.error(.Dashboard.sendFailure))
            return false
        }
    }

    private func failureMessage(for error: WalletError) -> LocalizedStringResource {
        switch error {
        case .recipientNotWallet:
            return .Dashboard.sendFailureRecipientNotWallet
        case .sendToSelf:
            return .Dashboard.sendFailureSelf
        case let .belowRentExemption(minLamports):
            let minSOL = SOL.toSOL(minLamports).formatted(.number.precision(.fractionLength(2...4)))
            return .Dashboard.sendFailureBelowRentExemption(minSOL)
        default:
            return .Dashboard.sendFailure
        }
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
