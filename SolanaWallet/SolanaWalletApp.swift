//
//  SolanaWalletApp.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 18/04/2026.
//

import CoreInfrastructure
import os
import SwiftUI

@main
struct SolanaWalletApp: App {
    @State private var appState: AppState
    private let deps: AppDependencies
    private static let logger = AppLog.logger(for: "AppState")

    init() {
        let deps: AppDependencies
        do {
            deps = try AppDependencies.make()
        } catch {
            fatalError("AppDependencies bootstrap failed: \(error)")
        }
        self.deps = deps

        let state = AppState()
        state.rehydrate(from: deps.keychain)
        _appState = State(initialValue: state)
    }

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps)
                .preferredColorScheme(.dark)
                .environment(appState)
                .task {
                    if
                        case .suspected = await JailbreakDetector(
                            probe: SystemFilesystemProbe(),
                            urlOpener: SystemURLOpener()
                        ).detect() {
                        Self.logger.info("Jailbreak suspected")
                    }
                }
        }
    }
}
