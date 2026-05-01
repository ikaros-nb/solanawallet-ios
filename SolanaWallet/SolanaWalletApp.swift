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
    @State private var appState = AppState()
    private let deps: AppDependencies
    private static let logger = AppLog.logger(for: "AppState")

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
                .task {
                    async let rehydrate: Void = appState.rehydrate(from: deps.keychain)
                    async let jailbreak = JailbreakDetector(
                        probe: SystemFilesystemProbe(),
                        urlOpener: SystemURLOpener()
                    ).detect()

                    _ = await rehydrate
                    if case .suspected = await jailbreak {
                        Self.logger.info("Jailbreak suspected")
                    }
                }
        }
    }
}
