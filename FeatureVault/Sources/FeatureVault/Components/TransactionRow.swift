//
//  TransactionRow.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import SwiftUI

struct TransactionRow: View {
    let transaction: VaultTransaction

    var body: some View {
        HStack(spacing: 12) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(iconColor)
                .padding(11)
                .background(background.opacity(0.09), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(transactionAt)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(amountText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(background)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardBackground(
            cornerRadius: 16,
            fillOpacity: 0.05,
            strokeOpacity: 0.06,
            highlight: nil
        )
    }

    private var image: Image {
        switch transaction.kind {
        case .deposit: Image(systemName: "tray.and.arrow.down.fill")
        case .withdraw: Image(systemName: "tray.and.arrow.up.fill")
        }
    }

    private var title: LocalizedStringResource {
        switch transaction.kind {
        case .deposit: .Vault.depositLabel
        case .withdraw: .Vault.withdrawLabel
        }
    }

    private var amountText: String {
        let symbol = String(localized: .Vault.symbol)
        let formatted = VLT.format(transaction.amount, sign: true)
        return "\(formatted) \(symbol)"
    }

    private var iconColor: Color {
        switch transaction.kind {
        case .deposit: .solanaGreen
        case .withdraw: .white
        }
    }

    private var background: Color {
        switch transaction.kind {
        case .deposit: .solanaGreen
        case .withdraw: .violet
        }
    }

    private var transactionAt: String {
        let timestamp = transaction.timestamp
        let datePart = timestamp.formatted(
            .dateTime.month(.abbreviated).day().year()
        )
        let timePart = timestamp.formatted(
            .dateTime.hour().minute()
        )
        return "\(datePart) · \(timePart)"
    }
}
