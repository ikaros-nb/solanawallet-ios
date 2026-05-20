//
//  WalletAvatar.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import CryptoKit
import SwiftUI

public struct WalletAvatar: View {
    private let seed: String
    private let size: CGFloat

    public init(seed: String, size: CGFloat = 24) {
        self.seed = seed
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: Self.gradientColors(for: seed),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
    }

    private static func gradientColors(for seed: String) -> [Color] {
        let digest = SHA256.hash(data: Data(seed.utf8))
        let bytes = Array(digest)
        let hue1 = Double(bytes[0]) / 255.0
        let hue2 = Double(bytes[1]) / 255.0
        return [
            Color(hue: hue1, saturation: 0.7, brightness: 0.85),
            Color(hue: hue2, saturation: 0.7, brightness: 0.55)
        ]
    }
}

#Preview {
    HStack(spacing: 12) {
        WalletAvatar(seed: "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU")
        WalletAvatar(seed: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263")
        WalletAvatar(seed: "EPjFWdd5AufqSSqeM2qN1xzybapC8GVEsLuT5wgF8Dt1v", size: 40)
    }
    .padding()
    .background(Color.deepIndigo)
}
