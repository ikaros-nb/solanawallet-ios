//
//  TokenRow.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreEntities
import SwiftUI

struct TokenRow: View {
    let token: SPLTokenAccount

    var body: some View {
        HStack(spacing: 12) {
            TokenAvatar(token: token)

            VStack(alignment: .leading, spacing: 2) {
                Text(token.name ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(token.symbol ?? "")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                token.uiAmount.formatted(
                    .number.precision(.fractionLength(0...min(Int(token.decimals), 6)))
                )
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
    }
}

private struct TokenAvatar: View {
    let token: SPLTokenAccount
    private static let palette: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .red]

    private var letter: String {
        let source = token.symbol ?? token.name ?? token.mint
        return String(source.first ?? "?").uppercased()
    }

    private var background: Color {
        let hash = abs(token.mint.hashValue)
        return Self.palette[hash % Self.palette.count]
    }

    var body: some View {
        Text(letter)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(background, in: .circle)
    }
}
