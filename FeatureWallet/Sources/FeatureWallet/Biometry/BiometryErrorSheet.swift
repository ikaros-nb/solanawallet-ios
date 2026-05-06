//
//  BiometryErrorSheet.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreUI
import SwiftUI

struct BiometryErrorSheet: View {
    var openSettings: () -> Void
    var dismissSheet: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(.Biometry.title)
                .typography(.sheetTitle)

            Text(.Biometry.description)
                .typography(.sheetBody)

            ActionButton(title: .Biometry.errorButtonSettings, style: .primaryPurple) {
                openSettings()
            }

            ActionButton(title: .Biometry.errorButtonCancel, style: .textOnly) {
                dismissSheet()
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
