//
//  RecoveryPhraseView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreUI
import SwiftUI

struct RecoveryPhraseView: View {
    let viewModel: RecoveryPhraseViewModel
    @Environment(RecoveryPhraseRouter.self) private var router

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                shieldLogo()
                Text(.RecoveryPhrase.title)
                    .typography(.title)
                Text(.RecoveryPhrase.description)
                    .typography(.body)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                Banner(
                    message: .RecoveryPhrase.bannerMessage,
                    icon: Image(systemName: "exclamationmark.triangle"),
                    style: .warning
                )

                ActionButton(
                    title: .RecoveryPhrase.buttonPhraseSaved,
                    icon: Image(systemName: "square.on.square"),
                    style: .primaryPurple
                ) {}

                Text(.RecoveryPhrase.footer)
                    .typography(.footer)
            }
        }
        .padding(.horizontal, 32)
        .background(Color.deepIndigo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(.RecoveryPhrase.navigationTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    private func shieldLogo() -> some View {
        ZStack {
            Circle()
                .fill(Color.card)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 80, height: 80)
                .shadow(color: Color.solanaGreen.opacity(0.13), radius: 80, x: 0, y: 0)
                .shadow(color: Color.solanaPurple.opacity(0.4), radius: 50, x: 0, y: 0)
            Image(systemName: "checkmark.shield")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundStyle(Color.solanaGreen)
        }
    }
}

#Preview {
    NavigationStack {
        RecoveryPhraseView(viewModel: RecoveryPhraseViewModel())
            .environment(RecoveryPhraseRouter(push: { _ in }))
    }
}
