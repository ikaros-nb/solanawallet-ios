//
//  RecoveryPhraseAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum RecoveryPhraseAssembly {
    public static func make() -> some View {
        RecoveryPhraseFlowContainer()
    }
}

private struct RecoveryPhraseFlowContainer: View {
    @State private var router = RecoveryPhraseRouter()
    @Environment(\.walletCreator) private var walletCreator
    @Environment(\.walletOnComplete) private var onComplete
    @Environment(OnboardingSession.self) private var session

    var body: some View {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                session: session,
                walletCreator: walletCreator,
                onComplete: onComplete
            )
        )
        .environment(router)
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .confirmation:
                Text("Confirmation sheet")
            }
        }
    }
}
