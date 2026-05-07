//
//  RecoveryPhraseView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreEntities
import CoreUI
import SwiftUI

struct RecoveryPhraseView: View {
    let viewModel: RecoveryPhraseViewModel
    @Environment(RecoveryPhraseRouter.self) private var router
    @State var isNarrow: Bool = false
    @State var isShort: Bool = false

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                shieldLogo()
                Text(.RecoveryPhrase.title)
                    .typography(.title)
                Text(.RecoveryPhrase.description)
                    .typography(.body)
                    .multilineTextAlignment(.center)
                recoveryPhraseGrid()

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
                ) {
                    Task {
                        await viewModel.createWallet(router: router)
                    }
                }

                Text(.RecoveryPhrase.footer)
                    .typography(.footer)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 12)
        .background(Color.deepIndigo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(.RecoveryPhrase.navigationTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            isNarrow = newValue.width < 375
            isShort = newValue.height < 700
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

    private func recoveryPhraseGrid() -> some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 12) {
            ForEach(0..<4, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { col in
                        let index = row * 3 + col
                        if index < viewModel.words.count {
                            wordCell(index: index + 1, word: viewModel.words[index])
                        }
                    }
                }
            }
        }
        .padding(.horizontal, isShort || isNarrow ? 10 : 16)
        .padding(.vertical, isShort || isNarrow ? 12 : 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: 1)
    }

    private func wordCell(index: Int, word: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index)")
                .font(.system(size: isShort || isNarrow ? 9 : 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.25))
            Text(word)
                .font(.system(size: isShort || isNarrow ? 12 : 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isShort || isNarrow ? 6 : 10)
        .padding(.vertical, isShort || isNarrow ? 8 : 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.05))
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    let session = OnboardingSession()
    session.setSeedPhrase(SecureSeedPhrase(words: [
        "margin", "pioneer", "segment", "liquid",
        "ocean", "frown", "spike", "ritual",
        "poverty", "vivid", "purity", "atlas"
    ]))
    return NavigationStack {
        RecoveryPhraseView(viewModel: RecoveryPhraseViewModel(session: session))
            .environment(RecoveryPhraseRouter(push: { _ in }))
    }
}
