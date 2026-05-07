//
//  RecoveryPhraseAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum RecoveryPhraseAssembly {
    public static func make(
        push: @escaping (any Hashable) -> Void
    ) -> some View {
        RecoveryPhraseFlowContainer(push: push)
    }
}

private struct RecoveryPhraseFlowContainer: View {
    private let push: (any Hashable) -> Void
    @State private var router: RecoveryPhraseRouter
    @Environment(\.walletCreator) private var walletCreator
    @Environment(\.walletOnComplete) private var onComplete
    @Environment(OnboardingSession.self) private var session

    init(push: @escaping (any Hashable) -> Void) {
        self.push = push
        _router = State(initialValue: RecoveryPhraseRouter(push: push))
    }

    var body: some View {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                session: session,
                walletCreator: walletCreator,
                onComplete: onComplete
            )
        )
        .environment(router)
        .navigationDestination(for: RecoveryPhraseRoute.self) { route in
            switch route {
            case .dashboard:
                Text("Dashboard")
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .confirmation:
                Text("Confirmation sheet")
            }
        }
    }
}
