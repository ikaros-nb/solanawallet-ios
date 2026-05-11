//
//  MainTabView.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreUI
import FeatureDashboard
import FeatureVault
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                DashboardAssembly.make()
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
        .preferredColorScheme(.dark)
}
