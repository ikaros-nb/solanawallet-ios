//
//  DashboardAssembly.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreDomain
import CoreEntities
import FeatureVault
import SwiftUI

public enum DashboardAssembly {
    public static func make(owner: Pubkey) -> some View {
        DashboardFlowContainer(owner: owner)
    }
}

private struct DashboardFlowContainer: View {
    private let owner: Pubkey
    @Environment(\.walletReader) private var walletReader
    @Environment(\.vaultBalanceReader) private var vaultBalanceReader

    init(owner: Pubkey) {
        self.owner = owner
    }

    var body: some View {
        let viewModel = DashboardViewModel(
            owner: owner,
            vaultBalanceReader: vaultBalanceReader,
            walletReader: walletReader
        )
        DashboardView(viewModel: viewModel)
    }
}
