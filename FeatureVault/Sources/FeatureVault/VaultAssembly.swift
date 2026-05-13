//
//  VaultAssembly.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import SwiftUI

public enum VaultAssembly {
    public static func make(owner: Pubkey) -> some View {
        VaultFlowContainer(owner: owner)
    }
}

private struct VaultFlowContainer: View {
    private let owner: Pubkey
    @Environment(\.walletReader) private var walletReader

    init(owner: Pubkey) {
        self.owner = owner
    }

    var body: some View {
        let viewModel = VaultViewModel(
            owner: owner,
            walletReader: walletReader
        )
        VaultView(viewModel: viewModel)
    }
}
