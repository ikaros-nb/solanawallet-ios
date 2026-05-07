//
//  BiometryAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum BiometryAssembly {
    public static func make(mode: WalletMode) -> some View {
        BiometryFlowContainer(mode: mode)
    }
}

private struct BiometryFlowContainer: View {
    private let mode: WalletMode
    @State private var router = BiometryRouter()
    @Environment(\.walletCreator) private var walletCreator
    @Environment(\.biometricAuthenticator) private var authenticator
    @Environment(OnboardingSession.self) private var session

    init(mode: WalletMode) {
        self.mode = mode
    }

    var body: some View {
        BiometryView(
            viewModel: BiometryViewModel(
                mode: mode,
                walletCreator: walletCreator,
                authenticator: authenticator,
                session: session
            )
        )
        .environment(router)
        .navigationDestination(for: BiometryRoute.self) { route in
            switch route {
            case .recoveryPhrase:
                RecoveryPhraseAssembly.make()
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {
            case .error:
                BiometryErrorSheet()
                    .environment(router)
            }
        }
    }
}
