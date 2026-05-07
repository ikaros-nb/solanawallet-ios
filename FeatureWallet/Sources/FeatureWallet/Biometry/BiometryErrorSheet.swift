//
//  BiometryErrorSheet.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreUI
import SwiftUI
import UIKit

struct BiometryErrorSheet: View {
    @Environment(BiometryRouter.self) private var router
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(.Biometry.title)
                .typography(.sheetTitle)

            Text(.Biometry.description)
                .typography(.sheetBody)

            ActionButton(title: .Biometry.errorButtonSettings, style: .primaryPurple) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }

            ActionButton(title: .Biometry.errorButtonCancel, style: .textOnly) {
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
