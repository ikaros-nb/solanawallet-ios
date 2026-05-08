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

            VStack(alignment: .leading, spacing: 10) {
                Text(.Dashboard.quickActionsLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.secondaryText)

                HStack(spacing: 10) {
                    Button {} label: {
                        Label {
                            Text(.Dashboard.buttonSendSOL)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondaryText)
                        } icon: {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(Color.solanaGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                            .shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 1)
                    )

                    Button {} label: {
                        Label {
                            Text(.Dashboard.buttonReceiveSOL)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondaryText)
                        } icon: {
                            Image(systemName: "arrow.down.backward")
                                .foregroundStyle(Color.solanaGreen)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                            .shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 1)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(.Dashboard.tokensLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                tokenRow(
                    name: "Solana",
                    shortName: "SOL",
                    symbol: "S",
                    amount: 245.82
                )
                tokenRow(
                    name: "Vault Token",
                    shortName: "VLT",
                    symbol: "V",
                    amount: 4_200_000
                )

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .background(Color.deepIndigo)
    }

    private func tokenRow(
        name: String,
        shortName: String,
        symbol: String,
        amount: Double
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.solanaPurple)
                    .frame(width: 36, height: 36)
                Text(symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(shortName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(amount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    DashboardView()
}
