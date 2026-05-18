//
//  VaultAssembly.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreDependencies
import CoreEntities
import CoreUI
import SwiftUI

public enum VaultAssembly {
    public static func make(owner: Pubkey) -> some View {
        VaultFlowContainer(owner: owner)
    }
}

private struct VaultFlowContainer: View {
    private let owner: Pubkey
    @State private var router = VaultRouter()
    @Environment(\.vaultStateReader) private var vaultStateReader
    @Environment(\.vaultBalanceReader) private var vaultBalanceReader
    @Environment(\.vaultHistoryReader) private var vaultHistoryReader
    @Environment(\.vaultTransactor) private var vaultTransactor
    @Environment(\.tokenBalanceReader) private var tokenBalanceReader
    @Environment(ToastCenter.self) private var toastCenter

    init(owner: Pubkey) {
        self.owner = owner
    }

    var body: some View {
        VaultFlowBody(
            router: router,
            initialViewModel: VaultViewModel(
                owner: owner,
                stateReader: vaultStateReader,
                balanceReader: vaultBalanceReader,
                historyReader: vaultHistoryReader,
                tokenBalanceReader: tokenBalanceReader,
                transactor: vaultTransactor,
                toastCenter: toastCenter
            )
        )
    }
}

// Owns the viewModel via @State so it survives body re-evaluations triggered by
// `.sheet(item: $router.presentedSheet)`. The container above can't own it because
// it needs @Environment values for construction — which can't be read in init.
private struct VaultFlowBody: View {
    @State private var viewModel: VaultViewModel
    @Bindable private var router: VaultRouter

    init(router: VaultRouter, initialViewModel: VaultViewModel) {
        self.router = router
        _viewModel = State(wrappedValue: initialViewModel)
    }

    var body: some View {
        VaultView(viewModel: viewModel)
            .environment(router)
            .sheet(item: $router.presentedSheet) { route in
                TransactionSheet(route: route, viewModel: viewModel)
                    .environment(router)
            }
    }
}
