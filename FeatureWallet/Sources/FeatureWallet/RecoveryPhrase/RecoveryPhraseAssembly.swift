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
    @State private var router: RecoveryPhraseRouter

    init(push: @escaping (any Hashable) -> Void) {
        _router = State(initialValue: RecoveryPhraseRouter(push: push))
    }

    var body: some View {
        RecoveryPhraseView(viewModel: RecoveryPhraseViewModel())
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
