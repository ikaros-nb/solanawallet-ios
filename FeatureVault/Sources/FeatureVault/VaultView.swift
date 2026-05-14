//
//  VaultView.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreDomain
import CoreEntities
import CoreUI
import SwiftUI

struct VaultView: View {
    @Bindable var viewModel: VaultViewModel
    @Environment(VaultRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            savingsSection()
            actionsSection()
            activitySection()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .background(Color.deepIndigo)
        .task {
            await viewModel.load()
        }
    }

    private func savingsSection() -> some View {
        VStack(spacing: 4) {
            Image(systemName: "lock")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.solanaGreen)
                .padding(18)
                .background {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.solanaPurple.opacity(0.25),
                                    Color.solanaGreen.opacity(0.13)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.06), lineWidth: 1)
                        }
                }
                .shadow(color: Color.solanaPurple, radius: 30, x: 0, y: 0)

            Spacer().frame(height: 16)

            Text(.Vault.savingsLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tertiaryText)
            vaultBalanceValue()
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.white)
            Text(.Vault.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.violet)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .cardBackground()
    }

    @ViewBuilder
    private func vaultBalanceValue() -> some View {
        if let balance = viewModel.vaultBalance {
            Text(VLT.format(balance))
        } else {
            Text(verbatim: "—")
        }
    }

    private func actionsSection() -> some View {
        HStack(spacing: 10) {
            ActionButton(
                title: .Vault.depositLabel,
                icon: Image(systemName: "tray.and.arrow.down.fill"),
                style: .primaryPurple,
                action: { router.present(.deposit) }
            )

            ActionButton(
                title: .Vault.withdrawLabel,
                icon: Image(systemName: "tray.and.arrow.up.fill"),
                style: .secondary,
                action: { router.present(.withdraw) }
            )
        }
    }

    private func activitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.Vault.activityLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    ForEach(viewModel.transactions ?? []) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
    }
}

#Preview {
    VaultView(
        viewModel: VaultViewModel(
            owner: "PreviewOwner",
            balanceReader: PreviewVaultReader(),
            historyReader: PreviewVaultHistoryReader(),
            tokenBalanceReader: PreviewTokenBalanceReader(),
            transactor: nil,
            toastCenter: ToastCenter()
        )
    )
    .environment(VaultRouter())
}

private struct PreviewTokenBalanceReader: TokenBalanceReader {
    nonisolated func fetchTokenBalance(for _: Pubkey, mint _: Pubkey) async throws -> Decimal {
        1234.5
    }
}

private struct PreviewVaultReader: VaultBalanceReader {
    nonisolated func fetchVaultBalance(for _: Pubkey) async throws -> Decimal {
        899.9995
    }
}

private struct PreviewVaultHistoryReader: VaultHistoryReader {
    nonisolated func fetchVaultTransactions(
        for _: Pubkey,
        limit _: Int
    ) async throws -> [VaultTransaction] {
        let now = Date()
        return [
            VaultTransaction(
                signature: "sig1",
                kind: .deposit,
                amount: 5,
                timestamp: now.addingTimeInterval(-86400),
                slot: 1
            ),
            VaultTransaction(
                signature: "sig2",
                kind: .deposit,
                amount: 10,
                timestamp: now.addingTimeInterval(-86400 * 4),
                slot: 2
            ),
            VaultTransaction(
                signature: "sig3",
                kind: .withdraw,
                amount: Decimal(string: "0.12") ?? 0,
                timestamp: now.addingTimeInterval(-86400 * 7),
                slot: 3
            )
        ]
    }
}
