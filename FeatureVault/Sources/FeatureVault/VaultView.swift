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
    @State var viewModel: VaultViewModel

    var body: some View {
        VStack(spacing: 16) {
            savingsSection()
            actionsSection()
            activitySection()

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .background(Color.deepIndigo)
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
            Text("500")
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

    private func actionsSection() -> some View {
        HStack(spacing: 10) {
            ActionButton(
                title: .Vault.depositLabel,
                icon: Image(systemName: "tray.and.arrow.down.fill"),
                style: .primaryPurple,
                action: {}
            )

            ActionButton(
                title: .Vault.withdrawLabel,
                icon: Image(systemName: "tray.and.arrow.up.fill"),
                style: .secondary,
                action: {}
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
                TransactionRow(
                    type: .deposit,
                    stringDate: "May 2, 2026 · 14:32",
                    amount: 5
                )

                TransactionRow(
                    type: .deposit,
                    stringDate: "Apr 28, 2026 · 09:15",
                    amount: 10
                )

                TransactionRow(
                    type: .withdraw,
                    stringDate: "Apr 25, 2026 · 11:18",
                    amount: 12
                )
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
    }
}

struct TransactionRow: View {
    enum TransactionType {
        case deposit
        case withdraw
    }

    let type: TransactionType
    let stringDate: String
    let amount: Int

    private var image: Image {
        switch type {
        case .deposit: Image(systemName: "tray.and.arrow.down.fill")
        case .withdraw: Image(systemName: "tray.and.arrow.up.fill")
        }
    }

    private var title: LocalizedStringResource {
        switch type {
        case .deposit: .Vault.depositLabel
        case .withdraw: .Vault.withdrawLabel
        }
    }

    private var amountText: String {
        let symbol = String(localized: .Vault.symbol)
        return switch type {
        case .deposit: "+\(amount) \(symbol)"
        case .withdraw: "-\(amount) \(symbol)"
        }
    }

    private var iconColor: Color {
        switch type {
        case .deposit: .solanaGreen
        case .withdraw: .white
        }
    }

    private var background: Color {
        switch type {
        case .deposit: .solanaGreen
        case .withdraw: .violet
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(iconColor)
                .padding(11)
                .background(background.opacity(0.09), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(stringDate)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(amountText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(background)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardBackground(
            cornerRadius: 16,
            fillOpacity: 0.05,
            strokeOpacity: 0.06,
            highlight: nil
        )
    }
}

#Preview {
    VaultView(
        viewModel: VaultViewModel(owner: "PreviewOwner", walletReader: PreviewWalletReader())
    )
}

private struct PreviewWalletReader: WalletReader {
    nonisolated func fetchBalance(for _: Pubkey) async throws -> Lamports {
        42_997_949_729
    }

    nonisolated func fetchTokenAccounts(for _: Pubkey) async throws -> [SPLTokenAccount] {
        [
            SPLTokenAccount(
                mint: "666gTuw7LC1auGbivZh1834HFquTHD5DwVtiR1jQv82E",
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
