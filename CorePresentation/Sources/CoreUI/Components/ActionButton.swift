//
//  ActionButton.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import SwiftUI

public struct ActionButton: View {
    public enum Style {
        case primary
        case secondary
    }

    let title: LocalizedStringResource
    let style: Style
    let action: () -> Void

    public init(
        title: LocalizedStringResource,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(background)
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.violet, Color.solanaPurple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(180))
        case .secondary:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }
}
