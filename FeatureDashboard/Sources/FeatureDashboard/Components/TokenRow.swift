//
//  TokenRow.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import SwiftUI

struct TokenRow: View {
    let name: String
    let shortName: String
    let symbol: String
    let amount: Double

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.solanaPurple)
                    .frame(width: 36, height: 36)
                Text(symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(shortName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(amount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
    }
}
