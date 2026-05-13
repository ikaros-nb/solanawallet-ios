//
//  VaultViewModel.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation

@Observable
@MainActor
final class VaultViewModel {
    private let owner: Pubkey
    private let walletReader: (any WalletReader)?

    init(owner: Pubkey, walletReader: (any WalletReader)?) {
        self.walletReader = walletReader
        self.owner = owner
    }
}
