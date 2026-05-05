//
//  PressScaleButtonStyle.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 05/05/2026.
//

import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var animation: Animation = .snappy(duration: 0.15)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(animation, value: configuration.isPressed)
    }
}
