//
//  JailbreakDetector.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import Foundation
import UIKit

public struct JailbreakDetector: Sendable {
    public enum JailbreakRisk {
        case none
        case suspected
    }

    public static let shared = JailbreakDetector()

    private init() {}

    @MainActor
    public func detect() -> JailbreakRisk {
        if isSimulator {
            .none
        } else if isContainsSuspiciousApps() || isSuspiciousSystemPathsExists() {
            .suspected
        } else if hasSandboxViolation() {
            .suspected
        } else if hasCydiaInstalled() {
            .suspected
        } else {
            .none
        }
    }

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private func isContainsSuspiciousApps() -> Bool {
        for path in suspiciousAppsPathToCheck where FileManager.default.fileExists(atPath: path) {
            return true
        }
        return false
    }

    private func isSuspiciousSystemPathsExists() -> Bool {
        for path in suspiciousSystemPathsToCheck where FileManager.default.fileExists(atPath: path) {
            return true
        }
        return false
    }

    private func hasSandboxViolation() -> Bool {
        do {
            try "sandbox_test".write(toFile: "/private/sandbox_test", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/sandbox_test")
            return true
        } catch {
            return false
        }
    }

    @MainActor
    private func hasCydiaInstalled() -> Bool {
        UIApplication.shared.canOpenURL(URL(string: "cydia://")!) ||
            UIApplication.shared.canOpenURL(URL(string: "sileo://")!) ||
            UIApplication.shared.canOpenURL(URL(string: "zbra://")!)
    }

    // MARK: - Path Lists

    private var suspiciousAppsPathToCheck: [String] {
        [
            // Traditional jailbreaks
            "/Applications/Cydia.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",

            // Modern jailbreaks
            "/Applications/Palera1n.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/TrollStore.app",
            "/var/containers/Bundle/Application/TrollStore.app",

            // Checkra1n
            "/Applications/checkra1n.app",

            // Rootless jailbreak paths
            "/var/jb/Applications/Cydia.app",
            "/var/jb/Applications/Sileo.app",
            "/var/jb/Applications/Zebra.app"
        ]
    }

    private var suspiciousSystemPathsToCheck: [String] {
        [
            // Traditional paths
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/usr/bin/sshd",
            "/usr/libexec/sftp-server",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/bin/bash",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",

            // Modern jailbreak paths
            "/var/jb", // Rootless jailbreak root
            "/var/binpack", // Checkm8 jailbreak
            "/var/containers/Bundle/tweaksupport",
            "/var/mobile/Library/palera1n",
            "/var/mobile/Library/xyz.willy.Zebra",
            "/var/lib/undecimus",

            // Palera1n specific
            "/var/jb/basebin",
            "/var/jb/usr",
            "/var/jb/etc",
            "/var/jb/Library",
            "/var/jb/.installed_palera1n",
            "/var/binpack/Applications",
            "/var/binpack/usr",

            // TrollStore
            "/var/containers/Bundle/Application/trollstorehelper",
            "/var/containers/Bundle/trollstore",

            // Bootstrap files
            "/var/jb/preboot",
            "/var/jb/var"
        ]
    }
}
