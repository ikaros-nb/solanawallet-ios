//
//  RootView.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 18/04/2026.
//

import FeatureWallet
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    let deps: AppDependencies

    var body: some View {
        if appState.isOnboarded {
            Text("MainTabView")
        } else {
            WelcomeAssembly.make()
        }
    }
}

#Preview {
    // swiftlint:disable:next force_try
    RootView(deps: try! .make())
        .environment(AppState())
}
