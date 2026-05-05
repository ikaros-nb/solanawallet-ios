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
                Button(action: {}, label: {
                    Text(.Welcome.buttonCreateWallet)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.violet, Color.solanaPurple],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .rotationEffect(.degrees(180))
                        )
                })

                Button(action: {}, label: {
                    Text(.Welcome.buttonImportWallet)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.08))
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                })

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
