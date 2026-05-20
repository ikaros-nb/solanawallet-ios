//
//  WalletPill.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import SwiftUI

public struct WalletPill: View {
    private let seed: String
    private let label: String

    public init(seed: String, label: String) {
        self.seed = seed
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 8) {
            WalletAvatar(seed: seed, size: 22)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(.white.opacity(0.08))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        WalletPill(
            seed: "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU",
            label: "7xKX…gAsU"
        )
        WalletPill(
            seed: "EPjFWdd5AufqSSqeM2qN1xzybapC8GVEsLuT5wgF8Dt1v",
            label: "EPjF…Dt1v"
        )
    }
    .padding()
    .background(Color.deepIndigo)
}
