//
//  SendSheet.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreUI
import SwiftUI

struct SendSheet: View {
    let route: DashboardSheetRoute
    let viewModel: DashboardViewModel
    @Environment(DashboardRouter.self) private var router

    @State private var amount: Decimal?
    @State private var destination: String = ""

    private static let base58Alphabet = Set("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    private var availableSOL: Decimal {
        viewModel.solBalanceDecimal ?? 0
    }

    private var isBusy: Bool {
        viewModel.isTransacting
    }

    private var trimmedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAddressStructurallyValid: Bool {
        let trimmed = trimmedDestination
        guard (32...44).contains(trimmed.count) else { return false }
        return trimmed.allSatisfy(Self.base58Alphabet.contains)
    }

    private var isAmountValid: Bool {
        guard let amount, amount > 0 else { return false }
        return amount <= availableSOL
    }

    private var isFormValid: Bool {
        isAmountValid && isAddressStructurallyValid
    }

    private var availableAmountText: String {
        let symbol = String(localized: .Dashboard.sendSymbol)
        let value = (availableSOL as NSDecimalNumber).doubleValue
        let formatted = value.formatted(.number.precision(.fractionLength(2...4)))
        return "\(formatted) \(symbol)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(.Dashboard.sendTitle)
                    .typography(.sheetTitle)

                Spacer()

                Button {
                    router.dismissSheet()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
                .disabled(isBusy)
            }

            Text(.Dashboard.sendBody)
                .typography(.sheetBody)

            VStack(alignment: .leading, spacing: 8) {
                Text(.Dashboard.sendAmountLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                HStack {
                    TextField(
                        "0.00",
                        value: $amount,
                        format: .number.precision(.fractionLength(0...9))
                    )
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .tint(Color.solanaGreen)

                    Text(.Dashboard.sendSymbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.tertiaryText)
                }
                .padding(16)
                .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.Dashboard.sendDestinationLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                TextField(
                    String(localized: .Dashboard.sendDestinationPlaceholder),
                    text: $destination
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
                .tint(Color.solanaGreen)
                .padding(16)
                .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)
            }

            HStack {
                Text(.Dashboard.sendBalanceLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
                Spacer()
                Text(availableAmountText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.solanaGreen)
            }

            ActionButton(
                title: .Dashboard.sendButton,
                icon: Image(systemName: "arrow.up.right"),
                style: .primaryGreen
            ) {
                guard let amount else { return }
                Task { await submit(amount: amount) }
            }
            .disabled(!isFormValid || isBusy)
        }
        .padding(.top, 44)
        .padding(.horizontal, 32)
        .presentationBackground(Color.card)
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
    }

    private func submit(amount: Decimal) async {
        let recipient = trimmedDestination
        let success = await viewModel.send(amount: amount, to: recipient)
        if success { router.dismissSheet() }
    }
}
