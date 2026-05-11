//
//  QuickActionButton.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreUI
import SwiftUI

struct QuickActionButton: View {
    let icon: Image
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
            } icon: {
                icon
                    .foregroundStyle(Color.solanaGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .cardBackground(cornerRadius: 16)
    }
}
