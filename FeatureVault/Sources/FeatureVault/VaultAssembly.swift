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
    @Environment(\.vaultReader) private var vaultReader
    @Environment(\.vaultHistoryReader) private var vaultHistoryReader

    init(owner: Pubkey) {
        self.owner = owner
    }

    var body: some View {
        let viewModel = VaultViewModel(
            owner: owner,
            vaultReader: vaultReader,
            historyReader: vaultHistoryReader
        )
        VaultView(viewModel: viewModel)
    }
}
