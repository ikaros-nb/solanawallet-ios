struct TransactionSheet: View {
    enum Kind {
        case deposit
        case withdraw

        var content: Content {
            switch self {
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
    }

    struct Content {
        let title: LocalizedStringResource
        let description: LocalizedStringResource
        let balanceLabel: LocalizedStringResource
        let buttonLabel: LocalizedStringResource
        let buttonIcon: Image
        let buttonStyle: ActionButton.Style
    }

    let kind: Kind
    let availableAmount: Decimal

    @State private var amount: Decimal?

    private var content: Content {
        kind.content
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

                Button {} label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
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

            ActionButton(
                title: content.buttonLabel,
                icon: content.buttonIcon,
                style: content.buttonStyle
            ) {}
                .disabled(!isAmountValid)
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
}
