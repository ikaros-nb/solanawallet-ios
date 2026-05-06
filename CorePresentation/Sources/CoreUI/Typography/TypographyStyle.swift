//
//  TypographyStyle.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

public enum TypographyStyle {
    /// Large title for main screens (26, bold, white)
    case title
    /// Standard body text (15, regular, secondaryText)
    case body
    /// Small footer text (12, regular, footerText)
    case footer
    /// Button text (16, semibold) - Note: color usually managed by button style
    case button
    /// Button icon (18, semibold) - Note: color usually managed by button style
    case buttonIcon
    /// Sheet title (20, semibold, white)
    case sheetTitle
    /// Sheet body (14, regular, secondaryText)
    case sheetBody

    var font: Font {
        switch self {
        case .title: .system(size: 26, weight: .bold)
        case .body: .system(size: 15, weight: .regular)
        case .footer: .system(size: 12, weight: .regular)
        case .button: .system(size: 16, weight: .semibold)
        case .buttonIcon: .system(size: 18, weight: .semibold)
        case .sheetTitle: .system(size: 20, weight: .semibold)
        case .sheetBody: .system(size: 14, weight: .regular)
        }
    }

    var color: Color? {
        switch self {
        case .title, .sheetTitle: .white
        case .body, .sheetBody: .secondaryText
        case .footer: .footerText
        case .button, .buttonIcon: nil
        }
    }
}
