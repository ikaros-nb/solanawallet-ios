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
    var body: some Scene {
        WindowGroup {
            ContentView()
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
