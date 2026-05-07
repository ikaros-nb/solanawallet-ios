//
//  WelcomeAssembly.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import SwiftUI

public enum WelcomeAssembly {
    public static func make() -> some View {
        WelcomeFlowContainer()
    }
}

private struct WelcomeFlowContainer: View {
    @State private var router = WelcomeRouter()
    @State private var session = OnboardingSession()

    var body: some View {
        NavigationStack(path: $router.path) {
            WelcomeView()
                .navigationDestination(for: WelcomeRoute.self) { route in
                    switch route {
                    case let .biometry(mode):
                        BiometryAssembly.make(mode: mode) { router.path.append($0) }
                    }
                }
        }
        .environment(router)
        .environment(session)
    }
}
