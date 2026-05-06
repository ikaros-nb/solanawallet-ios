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
        push: @escaping (BiometryRoute) -> Void
    ) -> some View {
        BiometryFlowContainer(mode: mode, push: push)
    }
}

private struct BiometryFlowContainer: View {
    private let mode: WalletMode
    @State private var router: BiometryRouter

    init(mode: WalletMode, push: @escaping (BiometryRoute) -> Void) {
        self.mode = mode
        _router = State(initialValue: BiometryRouter(push: push))
    }

    var body: some View {
        BiometryView(viewModel: BiometryViewModel(mode: mode))
            .environment(router)
            .navigationDestination(for: BiometryRoute.self) { route in
                switch route {
                case .createWallet:
                    Text("Create wallet")
                case .importWallet:
                    Text("Import wallet")
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
