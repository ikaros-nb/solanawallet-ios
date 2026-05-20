//
//  AppState.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 02/05/2026.
//

import CoreDomain
import CoreEntities
import CoreInfrastructure
import Foundation
import Observation
import os
import SolanaSwift

@MainActor
@Observable
final class AppState {
    var activeWallet: WalletAccount?
    var isOnboarded: Bool {
        activeWallet != nil
    }

    /// Set during ``rehydrate(from:biometric:)`` when the device's biometric
    /// set has changed since the keypair was sealed. UI observes this to
    /// surface a one-shot toast and flips it back to `false` after firing.
    var pendingBiometryChangeWarning: Bool = false

    private static let logger = AppLog.logger(for: "AppState")
    private static let biometryLogger = AppLog.logger(for: "Biometry")

    init() {}

    func rehydrate(from keychain: KeychainWalletStore, biometric: any BiometricAuthenticator) {
        do {
            guard let data = try keychain.loadPublicKey() else {
                activeWallet = nil
                return
            }
            let base58 = try PublicKey(data: data).base58EncodedString
            activeWallet = WalletAccount(pubkey: base58)
        } catch {
            Self.logger.error("Rehydration failed: \(error, privacy: .public)")
            activeWallet = nil
            return
        }
        detectBiometricChange(keychain: keychain, biometric: biometric)
    }

    /// Compares the persisted biometric-set hash against the device's current
    /// hash. On a real change, sets the warning flag and refreshes the baseline
    /// so the next launch is silent. See plan: detection-only, no re-arm flow.
    private func detectBiometricChange(
        keychain: KeychainWalletStore,
        biometric: any BiometricAuthenticator
    ) {
        let stored: Data?
        do {
            stored = try keychain.loadBiometryState()
        } catch {
            Self.biometryLogger.error("Biometry baseline load failed: \(error, privacy: .public)")
            return
        }
        let current = biometric.currentBiometryStateHash()

        switch (stored, current) {
        case let (nil, current?):
            // First run / upgrade from pre-feature install: capture silently.
            try? keychain.saveBiometryState(current)
        case let (stored?, current?) where stored != current:
            Self.biometryLogger.notice("Biometric set changed since keypair was sealed")
            pendingBiometryChangeWarning = true
            try? keychain.saveBiometryState(current)
        case (.some, nil):
            // Biometry removed entirely. The keypair's biometric ACL branch is
            // dead; surface the warning and drop the baseline so a future
            // re-enrollment is treated as a fresh first run.
            Self.biometryLogger.notice("Biometric set removed since keypair was sealed")
            pendingBiometryChangeWarning = true
            try? keychain.clearBiometryState()
        default:
            break
        }
    }
}
