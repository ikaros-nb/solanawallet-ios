//
//  RootView.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 18/04/2026.
//

import CoreInfrastructure
import FeatureDashboard
import FeatureVault
import FeatureWallet
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    let deps: AppDependencies

    var body: some View {
        if appState.isOnboarded {
//            VStack(spacing: 16) {
//                Text("MainTabView")
//                #if DEBUG
//                Button("Reset wallet", role: .destructive) {
//                    try? deps.keychain.reset()
//                    appState.activeWallet = nil
//                }
//                #endif
//            }
            MainTabView()
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
}

#Preview {
    // swiftlint:disable:next force_try
    RootView(deps: try! .make())
        .environment(AppState())
}
