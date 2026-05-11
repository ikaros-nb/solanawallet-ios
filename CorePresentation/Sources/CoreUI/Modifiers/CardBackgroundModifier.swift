//
//  CardBackgroundModifier.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import SwiftUI

public struct CardBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillOpacity: Double
    let strokeOpacity: Double
    let highlight: Color?

    public func body(content: Content) -> some View {
        content.background(background)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(fillOpacity))
            .stroke(.white.opacity(strokeOpacity), lineWidth: 1)

        if let highlight {
            shape.shadow(color: highlight, radius: 0, x: 0, y: 1)
        } else {
            shape
        }
    }
}

public extension View {
    func cardBackground(
        cornerRadius: CGFloat = 24,
        fillOpacity: Double = 0.08,
        strokeOpacity: Double = 0.1,
        highlight: Color? = .white.opacity(0.8)
    ) -> some View {
        modifier(CardBackgroundModifier(
            cornerRadius: cornerRadius,
            fillOpacity: fillOpacity,
            strokeOpacity: strokeOpacity,
            highlight: highlight
        ))
    }
}
