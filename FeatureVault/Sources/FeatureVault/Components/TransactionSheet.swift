//
//  TransactionSheet.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreEntities
import CoreUI
import SwiftUI

struct TransactionSheet: View {
    private struct Content {
        let title: LocalizedStringResource
        let description: LocalizedStringResource
        let balanceLabel: LocalizedStringResource
        let buttonLabel: LocalizedStringResource
        let buttonIcon: Image
        let buttonStyle: ActionButton.Style
    }

    let route: VaultSheetRoute
    let viewModel: VaultViewModel
    @Environment(VaultRouter.self) private var router

    @State private var amount: Decimal?

    private var availableAmount: Decimal {
        viewModel.vaultBalance ?? 0
    }

    private var isBusy: Bool {
        viewModel.isTransacting
    }

    private var errorMessage: String? {
        viewModel.transactionError.map { "\($0)" }
    }

    private var content: Content {
        switch route {
        case .deposit:
            Content(
                title: .Vault.transactionDepositTitle,
                description: .Vault.transactionDepositBody,
                balanceLabel: .Vault.transactionBalanceLabel,
                buttonLabel: .Vault.transactionDepositButton,
                buttonIcon: Image(systemName: "tray.and.arrow.down.fill"),
                buttonStyle: .primaryPurple
            )
        case .withdraw:
            Content(
                title: .Vault.transactionWithdrawTitle,
                description: .Vault.transactionWithdrawBody,
                balanceLabel: .Vault.transactionSavingsLabel,
                buttonLabel: .Vault.transactionWithdrawButton,
                buttonIcon: Image(systemName: "tray.and.arrow.up.fill"),
                buttonStyle: .secondary
            )
        }
    }

    private var isAmountValid: Bool {
        guard let amount, amount > 0 else { return false }
        return amount <= availableAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(content.title)
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

            Text(content.description)
                .typography(.sheetBody)

            VStack(alignment: .leading, spacing: 8) {
                Text(.Vault.transactionAmountLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                HStack {
                    TextField(
                        "0.00",
                        value: $amount,
                        format: .number.precision(.fractionLength(0...Int(VLT.decimals)))
                    )
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .tint(Color.solanaPurple)

                    Text(.Vault.symbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.tertiaryText)
                }
                .padding(16)
                .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)
            }

            HStack {
                Text(content.balanceLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.tertiaryText)
                Spacer()
                Text(availableAmountText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.solanaGreen)
            }

            if let errorMessage {
                Text(verbatim: errorMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.negative)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ActionButton(
                title: content.buttonLabel,
                icon: content.buttonIcon,
                style: content.buttonStyle
            ) {
                guard let amount else { return }
                Task { await submit(amount: amount) }
            }
            .disabled(!isAmountValid || isBusy)
        }
        .padding(.top, 44)
        .padding(.horizontal, 32)
        .presentationBackground(Color.card)
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
    }

    private var availableAmountText: String {
        let symbol = String(localized: .Vault.symbol)
        let formatted = VLT.format(availableAmount)
        return "\(formatted) \(symbol)"
    }

    private func submit(amount: Decimal) async {
        let success: Bool = switch route {
        case .deposit: await viewModel.deposit(amount: amount)
        case .withdraw: await viewModel.withdraw(amount: amount)
        }
        if success { router.dismissSheet() }
    }
}
