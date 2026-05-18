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

    private var displayName: String {
        if let name = token.name, !name.isEmpty { return name }
        if let symbol = token.symbol, !symbol.isEmpty { return symbol }
        return truncatedMint(token.mint)
    }

    private var displaySymbol: String {
        if let symbol = token.symbol, !symbol.isEmpty { return symbol }
        if token.name?.isEmpty == false { return "" }
        return truncatedMint(token.mint)
    }

    var body: some View {
        HStack(spacing: 12) {
            TokenAvatar(token: token)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(displaySymbol)
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

private func truncatedMint(_ mint: String) -> String {
    guard mint.count > 8 else { return mint }
    return mint.prefix(4) + "…" + mint.suffix(4)
}

private struct TokenAvatar: View {
    let token: SPLTokenAccount
    private static let palette: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo, .red]

    private var letter: String {
        let source = token.symbol ?? token.name ?? token.mint
        return String(source.first ?? "?").uppercased()
    }

    private var background: Color {
        var sum = 0
        for byte in token.mint.utf8 {
            sum = (sum &* 31 &+ Int(byte)) & 0x7FFF_FFFF
        }
        return Self.palette[sum % Self.palette.count]
    }

    var body: some View {
        Text(letter)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(background, in: .circle)
    }
}
