//
//  QuickActionButton.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .shadow(color: .white.opacity(0.8), radius: 0, x: 0, y: 1)
        )
    }
}
