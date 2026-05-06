//
//  TypographyModifier.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public struct TypographyModifier: ViewModifier {
    let style: TypographyStyle

    public func body(content: Content) -> some View {
        let contentWithFont = content.font(style.font)

        if let color = style.color {
            contentWithFont.foregroundStyle(color)
        } else {
            contentWithFont
        }
    }
}

public extension View {
    /// Applies a predefined typography style to the view.
    /// - Parameter style: The `TypographyStyle` to apply.
    /// - Returns: A view modified with the specified typography properties.
    func typography(_ style: TypographyStyle) -> some View {
        modifier(TypographyModifier(style: style))
    }
}
