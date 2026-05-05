//
//  ActionButton.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import SwiftUI

public struct ActionButton: View {
    public enum Style {
        case primaryGreen
        case primaryPurple
        case secondary
        case textOnly
    }

    let title: LocalizedStringResource
    let icon: Image?
    let style: Style
    let action: () -> Void

    public init(
        title: LocalizedStringResource,
        icon: Image? = nil,
        style: Style,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }, label: {
            buttonLabel
                .foregroundStyle(foregroundStyle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(background)
        })
        .buttonStyle(PressScaleButtonStyle())
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if let icon {
            Label {
                text
            } icon: {
                icon
                    .font(.system(size: 18, weight: .semibold))
            }
            .labelStyle(.titleAndIcon)
        } else {
            text
        }
    }

    private var text: Text {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
    }

    private var foregroundStyle: Color {
        switch style {
        case .primaryPurple, .secondary: .white
        case .primaryGreen: .black
        case .textOnly: .secondaryText
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primaryGreen:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.secondaryGreen, Color.solanaGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(180))
        case .primaryPurple:
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
        case .textOnly:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionButton(title: "Create a new wallet", style: .primaryPurple, action: {})
        ActionButton(title: "Import existing wallet", style: .secondary, action: {})
        ActionButton(
            title: "Enable Face ID",
            icon: Image(systemName: "faceid"),
            style: .primaryPurple,
            action: {}
        )
        ActionButton(
            title: "Yes, I saved it",
            icon: Image(systemName: "checkmark.shield"),
            style: .primaryGreen,
            action: {}
        )
        ActionButton(title: "Go back", style: .textOnly, action: {})
    }
    .padding(16)
    .background(.black)
}
