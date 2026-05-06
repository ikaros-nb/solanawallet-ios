//
//  BiometryAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum BiometryAssembly {
    public static func make(mode: WalletMode, push: @escaping (BiometryRoute) -> Void) -> some View {
        BiometryView(viewModel: BiometryViewModel(mode: mode))
            .environment(BiometryRouter(push: push))
            .navigationDestination(for: BiometryRoute.self) { route in
                switch route {
                case .createWallet:
                    Text("Create wallet")
                case .importWallet:
                    Text("Import wallet")
                }
            }
    }
}
