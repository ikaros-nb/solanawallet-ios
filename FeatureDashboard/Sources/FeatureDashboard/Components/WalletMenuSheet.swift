//
//  WalletMenuSheet.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import CoreEntities
import CoreUI
import SwiftUI

struct WalletMenuSheet: View {
    let owner: Pubkey
    @Environment(DashboardRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(\.walletOnRemove) private var walletOnRemove
    @State private var showRemoveConfirm = false
    @State private var isRemoving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(.Dashboard.walletMenuTitle)
                    .typography(.sheetTitle)

                Spacer()

                Button {
                    router.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.Dashboard.walletMenuAddressLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                HStack(spacing: 10) {
                    WalletAvatar(seed: owner, size: 28)
                    Text(truncatedAddress(owner))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)

            Spacer()

            ActionButton(
                title: .Dashboard.walletRemoveButton,
                icon: Image(systemName: "trash"),
                style: .secondary
            ) {
                showRemoveConfirm = true
            }
            .disabled(isRemoving)
        }
        .padding(.top, 44)
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .presentationBackground(Color.card)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .alert(
            Text(.Dashboard.walletRemoveAlertTitle),
            isPresented: $showRemoveConfirm
        ) {
            Button(role: .destructive) {
                removeWallet()
            } label: {
                Text(.Dashboard.walletRemoveAlertConfirm)
            }
            Button(role: .cancel) {} label: {
                Text(.Dashboard.walletRemoveAlertCancel)
            }
        } message: {
            Text(.Dashboard.walletRemoveAlertMessage)
        }
    }

    private func removeWallet() {
        guard !isRemoving, let walletOnRemove else { return }
        isRemoving = true
        Task {
            defer { isRemoving = false }
            do {
                try await walletOnRemove()
            } catch {
                toastCenter.show(.error(.Dashboard.walletRemoveFailure))
            }
        }
    }
}
