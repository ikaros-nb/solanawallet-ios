//
//  MainTabView.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreEntities
import CoreUI
import FeatureDashboard
import FeatureVault
import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                if let owner = appState.activeWallet?.pubkey {
                    DashboardAssembly.make(owner: owner)
                }
            }

            Tab("Vault", systemImage: "lock") {
                VaultView()
            }
        }
        .tint(Color.solanaPurple)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
