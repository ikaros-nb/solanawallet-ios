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
    @Bindable var viewModel: RecoveryPhraseViewModel
    @Environment(RecoveryPhraseRouter.self) private var router
    @State private var isNarrow: Bool = false
    @State private var isShort: Bool = false
    @FocusState private var isPhraseFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack {
                switch viewModel.content {
                case let .create(content):
                    createContent(content)
                case let .importViaBIP39(content):
                    importContent(content)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.deepIndigo)
        .safeAreaInset(edge: .bottom) {
            Group {
                switch viewModel.content {
                case let .create(content):
                    createBottomBar(content)
                case let .importViaBIP39(content):
                    importBottomBar(content)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
        }
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

    private func createContent(_ content: RecoveryPhraseContent.Create) -> some View {
        VStack(spacing: 20) {
            logo(content.logo)
            Text(content.title)
                .typography(.title)
            Text(content.description)
                .typography(.body)
                .multilineTextAlignment(.center)
            recoveryPhraseGrid()
        }
    }

    private func createBottomBar(_ content: RecoveryPhraseContent.Create) -> some View {
        VStack(spacing: 16) {
            Banner(
                message: .RecoveryPhrase.bannerMessage,
                icon: Image(systemName: "exclamationmark.triangle"),
                style: .warning
            )

            ActionButton(
                title: content.buttonTitle,
                icon: Image(systemName: "square.on.square"),
                style: .primaryPurple
            ) {
                viewModel.createWallet(router: router)
            }
            .disabled(viewModel.words.isEmpty)

            Text(content.footer)
                .typography(.footer)
        }
    }

    private func importContent(_ content: RecoveryPhraseContent.Import) -> some View {
        VStack(spacing: 20) {
            logo(content.logo)
            Text(content.title)
                .typography(.title)
            Text(content.description)
                .typography(.body)
                .multilineTextAlignment(.center)

            TextField(
                text: $viewModel.importedPhrase,
                prompt: Text(content.placeholder).foregroundStyle(.white.opacity(0.25)),
                axis: .vertical
            ) {
                EmptyView()
            }
            .focused($isPhraseFieldFocused)
            .typography(.body)
            .foregroundStyle(.white)
            .lineLimit(5, reservesSpace: true)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )

            if let importError = viewModel.importError {
                Text(importError)
                    .foregroundStyle(Color.negative)
                    .typography(.footer)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                viewModel.pasteFromClipboard()
                isPhraseFieldFocused = false
            } label: {
                Label {
                    Text(content.clipboard)
                } icon: {
                    Image(systemName: "arrow.right.page.on.clipboard")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.violet)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.05))
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: 1)
        }
    }

    private func importBottomBar(_ content: RecoveryPhraseContent.Import) -> some View {
        VStack(spacing: 16) {
            ActionButton(
                title: content.buttonTitle,
                icon: Image(systemName: "tray.and.arrow.down"),
                style: .primaryPurple
            ) {
                isPhraseFieldFocused = false
                Task { await viewModel.importWallet() }
            }
            .disabled(viewModel.importedPhrase.isEmpty || viewModel.isImporting)

            Text(content.footer)
                .typography(.footer)
        }
    }

    private func logo(_ logo: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.card)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 80, height: 80)
                .shadow(color: Color.solanaGreen.opacity(0.13), radius: 80, x: 0, y: 0)
                .shadow(color: Color.solanaPurple.opacity(0.4), radius: 50, x: 0, y: 0)
            Image(systemName: logo)
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

#Preview("Create") {
    let session = OnboardingSession()
    session.setSeedPhrase(SecureSeedPhrase(words: [
        "margin", "pioneer", "segment", "liquid",
        "ocean", "frown", "spike", "ritual",
        "poverty", "vivid", "purity", "atlas"
    ]))
    return NavigationStack {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                mode: .create,
                session: session,
                walletCreator: nil,
                onComplete: nil
            )
        )
        .environment(RecoveryPhraseRouter())
    }
}

#Preview("Import") {
    let session = OnboardingSession()
    session.setSeedPhrase(SecureSeedPhrase(words: [
        "margin", "pioneer", "segment", "liquid",
        "ocean", "frown", "spike", "ritual",
        "poverty", "vivid", "purity", "atlas"
    ]))
    return NavigationStack {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                mode: .importViaBIP39,
                session: session,
                walletCreator: nil,
                onComplete: nil
            )
        )
        .environment(RecoveryPhraseRouter())
    }
}
