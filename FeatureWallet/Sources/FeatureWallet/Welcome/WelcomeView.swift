//
//  WelcomeView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import CoreUI
import SwiftUI

public struct WelcomeView: View {
    public init() {}

    public var body: some View {
        VStack {
            VStack(spacing: 20) {
                Spacer()

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
                    style: .primary
                ) {
                    print("Test")
                }

                ActionButton(
                    title: .Welcome.buttonImportWallet,
                    style: .secondary
                ) {
                    print("Test")
                }

                Text(.Welcome.footer)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.footerText)
            }
            .padding(.horizontal, 32)
        }
        .background(Color.deepIndigo)
    }
}

#Preview {
    WelcomeView()
}
