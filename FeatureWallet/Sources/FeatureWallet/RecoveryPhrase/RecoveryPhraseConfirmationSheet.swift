//
//  RecoveryPhraseConfirmationSheet.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreUI
import SwiftUI

struct RecoveryPhraseConfirmationSheet: View {
    let viewModel: RecoveryPhraseViewModel
    @Environment(RecoveryPhraseRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(.RecoveryPhrase.confirmationTitle)
                .typography(.sheetTitle)

            Text(.RecoveryPhrase.confirmationDescription)
                .typography(.sheetBody)

            ActionButton(
                title: .RecoveryPhrase.confirmationButtonYes,
                icon: Image(systemName: "checkmark.shield"),
                style: .primaryGreen
            ) {
                Task {
                    await viewModel.confirmCreation(router: router)
                }
            }

            ActionButton(title: .RecoveryPhrase.confirmationButtonGoBack, style: .textOnly) {
                router.dismissSheet()
            }
        }
        .padding(.top, 44)
        .padding(.horizontal, 32)
        .presentationBackground(Color.card)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
    }
}
