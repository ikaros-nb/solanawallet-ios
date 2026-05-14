//
//  RecoveryPhraseAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreDependencies
import SwiftUI

public enum RecoveryPhraseAssembly {
    public static func make(mode: WalletMode) -> some View {
        RecoveryPhraseFlowContainer(mode: mode)
    }
}

private struct RecoveryPhraseFlowContainer: View {
    private let mode: WalletMode
    @State private var router = RecoveryPhraseRouter()
    @Environment(\.walletCreator) private var walletCreator
    @Environment(\.walletOnComplete) private var onComplete
    @Environment(OnboardingSession.self) private var session

    init(mode: WalletMode) {
        self.mode = mode
    }

    var body: some View {
        let viewModel = RecoveryPhraseViewModel(
            mode: mode,
            session: session,
            walletCreator: walletCreator,
            onComplete: onComplete
        )
        RecoveryPhraseView(viewModel: viewModel)
            .environment(router)
            .sheet(item: $router.presentedSheet) { sheet in
                switch sheet {
                case .confirmation:
                    RecoveryPhraseConfirmationSheet(viewModel: viewModel)
                        .environment(router)
                }
            }
    }
}
