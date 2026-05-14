//
//  DashboardView.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreDomain
import CoreEntities
import CoreUI
import SwiftUI

struct DashboardView: View {
    @State var viewModel: DashboardViewModel

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                balanceSection()
                vaultSavingsSection()
                quickActionsSection()
                tokensSection()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.horizontal, 20)
        }
        .background(Color.deepIndigo)
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
    }

    private func balanceSection() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.Dashboard.solBalanceLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tertiaryText)
            balanceValue()
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .cardBackground()
    }

    @ViewBuilder
    private func balanceValue() -> some View {
        if let lamports = viewModel.solBalance {
            Text(.Dashboard.solBalanceValue(
                SOL.toSOL(lamports).formatted(.number.precision(.fractionLength(2...4)))
            ))
        } else {
            Text(verbatim: "—")
        }
    }

    private func vaultSavingsSection() -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.solanaPurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(.Dashboard.vaultSavingsLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(.Dashboard.vaultSavingsValue(
                    viewModel.vaultBalance.map { VLT.format($0) } ?? "—"
                ))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .cardBackground()
    }

    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.Dashboard.quickActionsLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.secondaryText)

            HStack(spacing: 10) {
                QuickActionButton(
                    icon: Image(systemName: "arrow.up.right"),
                    title: .Dashboard.buttonSendSOL,
                    action: {}
                )

                QuickActionButton(
                    icon: Image(systemName: "arrow.down.backward"),
                    title: .Dashboard.buttonReceiveSOL,
                    action: {}
                )
            }
        }
    }

    private func tokensSection() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(.Dashboard.tokensLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.tokens, id: \.mint) { token in
                TokenRow(token: token)
            }
        }
    }
}

#Preview {
    DashboardView(
        viewModel: DashboardViewModel(
            owner: "PreviewOwner",
            vaultBalanceReader: PreviewVaultReader(),
            walletReader: PreviewWalletReader(),
            toastCenter: ToastCenter()
        )
    )
}

private struct PreviewVaultReader: VaultBalanceReader {
    nonisolated func fetchVaultBalance(for _: Pubkey) async throws -> Decimal {
        899.9995
    }
}

private struct PreviewWalletReader: WalletReader {
    nonisolated func fetchBalance(for _: Pubkey) async throws -> Lamports {
        42_997_949_729
    }

    nonisolated func fetchTokenAccounts(for _: Pubkey) async throws -> [SPLTokenAccount] {
        [
            SPLTokenAccount(
                mint: VLT.mint,
                address: "PreviewVLTAccount",
                amount: 4_200_000_000,
                decimals: 9,
                name: "Vault Token",
                symbol: "VLT"
            ),
            SPLTokenAccount(
                mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8GVEsLuT5wgF8Dt1v",
                address: "PreviewUSDCAccount",
                amount: 1_500_000,
                decimals: 6,
                name: "USD Coin",
                symbol: "USDC"
            ),
            SPLTokenAccount(
                mint: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
                address: "PreviewBONKAccount",
                amount: 12_345_678_900,
                decimals: 5,
                name: "Bonk",
                symbol: "BONK"
            )
        ]
    }
}
