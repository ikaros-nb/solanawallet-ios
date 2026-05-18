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

enum SendAsset: Hashable {
    case sol
    case spl(SPLTokenAccount)
}

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

    var sendableAssets: [SendAsset] {
        var assets: [SendAsset] = []
        if let solBalance, solBalance > 0 {
            assets.append(.sol)
        }
        for token in tokens where token.amount > 0 {
            assets.append(.spl(token))
        }
        return assets
    }

    func availableBalance(for asset: SendAsset) -> Decimal {
        switch asset {
        case .sol:
            solBalanceDecimal ?? 0
        case let .spl(token):
            Decimal(token.amount) / pow(Decimal(10), Int(token.decimals))
        }
    }

    func decimals(for asset: SendAsset) -> Int {
        switch asset {
        case .sol:
            9
        case let .spl(token):
            Int(token.decimals)
        }
    }

    func symbol(for asset: SendAsset) -> String {
        switch asset {
        case .sol:
            String(localized: .Dashboard.sendSymbol)
        case let .spl(token):
            token.displaySymbol.isEmpty ? token.displayName : token.displaySymbol
        }
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
    func send(amount: Decimal, to recipient: Pubkey, asset: SendAsset) async -> Bool {
        guard let transactionSender, !isTransacting else { return false }
        isTransacting = true
        transactionError = nil
        defer { isTransacting = false }

        do {
            switch asset {
            case .sol:
                let lamports = NSDecimalNumber(decimal: amount * Decimal(SOL.lamportsPerSOL)).uint64Value
                _ = try await transactionSender.sendSOL(from: owner, to: recipient, amount: lamports)
            case let .spl(token):
                let baseUnits = NSDecimalNumber(
                    decimal: amount * pow(Decimal(10), Int(token.decimals))
                ).uint64Value
                _ = try await transactionSender.sendSPL(
                    from: owner,
                    token: token.ref,
                    to: recipient,
                    amount: baseUnits
                )
            }
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
        case .insufficientTokens:
            return .Dashboard.sendFailureInsufficientTokens
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
            tokens = try await walletReader.fetchTokenAccounts(for: owner).sorted(by: Self.tokenOrder)
        } catch let WalletError.staleTokenCache(cached, underlying) {
            tokens = cached.sorted(by: Self.tokenOrder)
            loadError = underlying
        } catch let error as WalletError {
            loadError = error
        } catch {
            loadError = .unknown(underlying: "\(error)")
        }
    }

    private static func tokenOrder(_ lhs: SPLTokenAccount, _ rhs: SPLTokenAccount) -> Bool {
        let lhsKnown = lhs.symbol?.isEmpty == false || lhs.name?.isEmpty == false
        let rhsKnown = rhs.symbol?.isEmpty == false || rhs.name?.isEmpty == false
        if lhsKnown != rhsKnown { return lhsKnown }
        let lhsKey = (lhs.symbol ?? lhs.name ?? lhs.mint).localizedLowercase
        let rhsKey = (rhs.symbol ?? rhs.name ?? rhs.mint).localizedLowercase
        if lhsKey != rhsKey { return lhsKey < rhsKey }
        return lhs.mint < rhs.mint
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
