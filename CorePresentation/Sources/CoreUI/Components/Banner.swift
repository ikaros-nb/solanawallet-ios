//
//  Banner.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public struct Banner: View {
    public enum Style {
        case warning
        case error
    }

    let message: LocalizedStringResource
    let icon: Image
    let style: Style

    public init(message: LocalizedStringResource, icon: Image, style: Style) {
        self.message = message
        self.icon = icon
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 12) {
            icon
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(color)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.07))
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    private var color: Color {
        switch style {
        case .warning: .warning
        case .error: .negative
        }
    }
}
