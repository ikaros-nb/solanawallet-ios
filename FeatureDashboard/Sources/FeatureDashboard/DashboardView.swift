//
//  DashboardView.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreUI
import SwiftUI

public struct DashboardView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            balanceSection()
            vaultSavingsSection()
            quickActionsSection()
            tokensSection()

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .background(Color.deepIndigo)
    }

    private func balanceSection() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.Dashboard.solBalanceLabel)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.tertiaryText)
            Text(.Dashboard.solBalanceValue(245.82))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.08))
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 1)
        )
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
                Text(.Dashboard.vaultSavingsValue(32.5))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.08))
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 1)
        )
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

            TokenRow(
                name: "Solana",
                shortName: "SOL",
                symbol: "S",
                amount: 245.82
            )
            TokenRow(
                name: "Vault Token",
                shortName: "VLT",
                symbol: "V",
                amount: 4_200_000
            )
        }
    }
}

#Preview {
    DashboardView()
}
