//
//  WelcomeView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import CoreUI
import SwiftUI

struct WelcomeView: View {
    @Environment(WalletNavigator.self) private var navigator

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Spacer()

                circleLogo()
                Text(.Welcome.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text(.Welcome.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                ActionButton(
                    title: .Welcome.buttonCreateWallet,
                    style: .primaryPurple
                ) {
                    navigator.push(WelcomeRoute.biometry(.create))
                }

                ActionButton(
                    title: .Welcome.buttonImportWallet,
                    style: .secondary
                ) {
                    navigator.push(WelcomeRoute.biometry(.importViaBIP39))
                }

                Text(.Welcome.footer)
                    .typography(.footer)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 12)
        .background(Color.deepIndigo)
    }

    private func circleLogo() -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.solanaGreen, Color.solanaPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(225))
                .frame(width: 120, height: 120)
                .shadow(color: Color.solanaGreen.opacity(0.4), radius: 40, x: 0, y: 8)
                .shadow(color: Color.solanaPurple.opacity(0.4), radius: 60, x: 0, y: 0)
            Image(systemName: "wallet.bifold")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(WalletNavigator())
}
