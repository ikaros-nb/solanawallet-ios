//
//  AppState.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 02/05/2026.
//

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

    private static let logger = AppLog.logger(for: "AppState")

    init() {}

    func rehydrate(from keychain: KeychainWalletStore) async {
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
        }
    }
}
