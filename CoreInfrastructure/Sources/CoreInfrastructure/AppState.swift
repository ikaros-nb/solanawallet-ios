//
//  AppState.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 02/05/2026.
//

import CoreEntities
import Foundation
import Observation
import os
import SolanaSwift

@MainActor
@Observable
public final class AppState {
    public var activeWallet: WalletAccount?
    public var isOnboarded: Bool {
        activeWallet != nil
    }

    private static let logger = AppLog.logger(for: "AppState")

    public init() {}

    public func rehydrate(from keychain: KeychainWalletStore) async {
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
