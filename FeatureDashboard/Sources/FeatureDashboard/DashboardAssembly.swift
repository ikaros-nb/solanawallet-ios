//
//  DashboardAssembly.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreDependencies
import CoreDomain
import CoreEntities
import CoreUI
import SwiftUI

public enum DashboardAssembly {
    public static func make(owner: Pubkey) -> some View {
        DashboardFlowContainer(owner: owner)
    }
}

private struct DashboardFlowContainer: View {
    private let owner: Pubkey
    @State private var router = DashboardRouter()
    @Environment(\.walletReader) private var walletReader
    @Environment(\.vaultBalanceReader) private var vaultBalanceReader
    @Environment(\.transactionSender) private var transactionSender
    @Environment(ToastCenter.self) private var toastCenter

    init(owner: Pubkey) {
        self.owner = owner
    }

    var body: some View {
        DashboardFlowBody(
            owner: owner,
            router: router,
            initialViewModel: DashboardViewModel(
                owner: owner,
                vaultBalanceReader: vaultBalanceReader,
                walletReader: walletReader,
                transactionSender: transactionSender,
                toastCenter: toastCenter
            )
        )
    }
}

// Owns the viewModel via @State so it survives body re-evaluations triggered by
// `.sheet(item: $router.presentedSheet)`. The container above can't own it because
// it needs @Environment values for construction — which can't be read in init.
private struct DashboardFlowBody: View {
    private let owner: Pubkey
    @State private var viewModel: DashboardViewModel
    @Bindable private var router: DashboardRouter

    init(owner: Pubkey, router: DashboardRouter, initialViewModel: DashboardViewModel) {
        self.owner = owner
        self.router = router
        _viewModel = State(wrappedValue: initialViewModel)
    }

    var body: some View {
        DashboardView(viewModel: viewModel)
            .environment(router)
            .sheet(item: $router.presentedSheet) { route in
                switch route {
                case .send:
                    SendSheet(route: route, viewModel: viewModel)
                        .environment(router)
                case .receive:
                    ReceiveSheet(owner: owner)
                        .environment(router)
                }
            }
    }
}
