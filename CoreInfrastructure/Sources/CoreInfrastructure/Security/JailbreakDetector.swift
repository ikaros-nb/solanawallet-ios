//
//  JailbreakDetector.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import Foundation

public struct JailbreakDetector: Sendable {
    public enum JailbreakRisk {
        case none
        case suspected
    }

    private let probe: FilesystemProbe
    private let urlOpener: URLOpener

    public init(probe: FilesystemProbe, urlOpener: URLOpener) {
        self.probe = probe
        self.urlOpener = urlOpener
    }

    public func detect() async -> JailbreakRisk {
        if hasSuspiciousApps() || hasSuspiciousSystemPaths() { return .suspected }
        if hasSandboxViolation() { return .suspected }
        if await hasCydiaInstalled() { return .suspected }
        return .none
    }

    private func hasSuspiciousApps() -> Bool {
        Self.suspiciousAppsPaths
            .contains { probe.fileExists(atPath: $0) }
    }

    private func hasSuspiciousSystemPaths() -> Bool {
        Self.suspiciousSystemPaths
            .contains { probe.fileExists(atPath: $0) }
    }

    private func hasSandboxViolation() -> Bool {
        probe.canWrite(toPath: Self.sandboxProbePath)
    }

    @MainActor
    private func hasCydiaInstalled() async -> Bool {
        for scheme in Self.suspiciousURLSchemes {
            if let url = URL(string: scheme), await urlOpener.canOpen(url) {
                return true
            }
        }
        return false
    }

    // MARK: - Known signatures (package-visible for tests)

    package static let sandboxProbePath = "/private/sandbox_test"

    package static let suspiciousURLSchemes: [String] = [
        "cydia://",
        "sileo://",
        "zbra://"
    ]

    package static let suspiciousAppsPaths: [String] = [
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

    package static let suspiciousSystemPaths: [String] = [
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
