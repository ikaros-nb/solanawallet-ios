//
//  SolanaWalletApp.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 18/04/2026.
//

import CoreInfrastructure
import SwiftUI

@main
struct SolanaWalletApp: App {
    @State private var appState = AppState()
    private let deps: AppDependencies

    init() {
        do {
            deps = try AppDependencies.make()
        } catch {
            fatalError("AppDependencies bootstrap failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
                .environment(appState)
                .task { await appState.rehydrate(from: deps.keychain) }
                .task {
                    let detector = JailbreakDetector(
                        probe: SystemFilesystemProbe(),
                        urlOpener: SystemURLOpener()
                    )
                    if case .suspected = await detector.detect() {
                        print("Jailbreak suspected")
                    }
                }
        }
    }
}
