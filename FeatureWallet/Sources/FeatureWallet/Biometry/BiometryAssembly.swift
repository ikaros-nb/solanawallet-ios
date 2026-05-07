//
//  BiometryAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum BiometryAssembly {
    public static func make(
        mode: WalletMode,
        push: @escaping (any Hashable) -> Void
    ) -> some View {
        BiometryFlowContainer(mode: mode, push: push)
    }
}

private struct BiometryFlowContainer: View {
    private let mode: WalletMode
    private let push: (any Hashable) -> Void
    @State private var router: BiometryRouter
    @Environment(\.walletCreator) private var walletCreator
    @Environment(OnboardingSession.self) private var session

    init(
        mode: WalletMode,
        push: @escaping (any Hashable) -> Void
    ) {
        self.mode = mode
        self.push = push
        _router = State(initialValue: BiometryRouter(push: push))
    }

    var body: some View {
        BiometryView(
            viewModel: BiometryViewModel(
                mode: mode,
                walletCreator: walletCreator,
                session: session
            )
        )
        .environment(router)
        .navigationDestination(for: BiometryRoute.self) { route in
            switch route {
            case .createWallet:
                RecoveryPhraseAssembly.make(push: push)
            case .importWallet:
                RecoveryPhraseAssembly.make(push: push)
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .error:
                BiometryErrorSheet(
                    openSettings: router.openSettings,
                    dismissSheet: router.dismissSheet
                )
            }
        }
    }
}
