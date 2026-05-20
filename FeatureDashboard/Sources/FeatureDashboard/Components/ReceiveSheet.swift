//
//  ReceiveSheet.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import CoreUI
import SwiftUI
import UIKit

struct ReceiveSheet: View {
    let owner: Pubkey
    @Environment(DashboardRouter.self) private var router
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(.Dashboard.receiveTitle)
                    .typography(.sheetTitle)

                Spacer()

                Button {
                    router.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
            }

            Text(.Dashboard.receiveBody)
                .typography(.sheetBody)

            VStack(alignment: .leading, spacing: 8) {
                Text(.Dashboard.receiveAddressLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                Text(owner)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                QRCode(from: owner)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(16)
            .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)

            ActionButton(
                title: .Dashboard.receiveButtonCopy,
                icon: Image(systemName: "square.on.square"),
                style: .primaryGreen
            ) {
                UIPasteboard.general.string = owner
                toastCenter.show(.success(.Dashboard.receiveCopySuccess))
            }
        }
        .padding(.top, 44)
        .padding(.horizontal, 32)
        .presentationBackground(Color.card)
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
    }
}
