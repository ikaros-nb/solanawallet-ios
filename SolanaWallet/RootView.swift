//
//  RootView.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 18/04/2026.
//

import CoreDependencies
import CoreInfrastructure
import CoreUI
import FeatureWallet
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var toastCenter = ToastCenter()
    let deps: AppDependencies

    var body: some View {
        Group {
            if appState.isOnboarded {
                MainTabView()
                    .environment(\.tokenBalanceReader, deps.solanaClient)
                    .environment(\.vaultBalanceReader, deps.solanaClient)
                    .environment(\.vaultHistoryReader, deps.solanaClient)
                    .environment(\.vaultTransactor, deps.solanaClient)
                    .environment(\.walletReader, deps.solanaClient)
            } else {
                WelcomeAssembly.make()
                    .environment(\.biometricAuthenticator, deps.biometricAuthenticator)
                    .environment(\.walletCreator, deps.walletCreator)
                    .environment(\.walletOnComplete) { account in
                        appState.activeWallet = account
                    }
            }
        }
        .environment(toastCenter)
        .toastOverlay(toastCenter)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    RootView(deps: try! .make())
        .environment(AppState())
}
