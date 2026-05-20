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
    @State private var selectedAsset: SendAsset = .sol
    @State private var isScannerPresented: Bool = false

    private var availableBalance: Decimal {
        viewModel.availableBalance(for: selectedAsset)
    }

    private var selectedSymbol: String {
        viewModel.symbol(for: selectedAsset)
    }

    private var selectedDecimals: Int {
        viewModel.decimals(for: selectedAsset)
    }

    private var sendableAssets: [SendAsset] {
        viewModel.sendableAssets
    }

    private var isBusy: Bool {
        viewModel.isTransacting
    }

    private var trimmedDestination: String {
        destination.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAddressStructurallyValid: Bool {
        SolanaAddressValidator.isStructurallyValid(trimmedDestination)
    }

    private var isAmountValid: Bool {
        guard let amount, amount > 0 else { return false }
        return amount <= availableBalance
    }

    private var isFormValid: Bool {
        isAmountValid && isAddressStructurallyValid
    }

    private var availableAmountText: String {
        let value = (availableBalance as NSDecimalNumber).doubleValue
        let formatted = value.formatted(.number.precision(.fractionLength(2...4)))
        return "\(formatted) \(selectedSymbol)"
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
                        format: .number.precision(.fractionLength(0...selectedDecimals))
                    )
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .tint(Color.solanaGreen)

                    assetPicker
                }
                .padding(16)
                .cardBackground(cornerRadius: 16, fillOpacity: 0.05, highlight: nil)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.Dashboard.sendDestinationLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)

                HStack(spacing: 12) {
                    TextField(
                        String(localized: .Dashboard.sendDestinationPlaceholder),
                        text: $destination
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(Color.solanaGreen)

                    Button {
                        isScannerPresented = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .disabled(isBusy)
                }
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
        .onChange(of: selectedAsset) { _, _ in
            amount = nil
        }
        .onAppear(perform: snapSelectedAssetIfNeeded)
        .onChange(of: sendableAssets) { _, _ in
            snapSelectedAssetIfNeeded()
        }
        .fullScreenCover(isPresented: $isScannerPresented) {
            QRScannerSheet { scanned in
                destination = scanned
                isScannerPresented = false
            }
        }
    }

    private func snapSelectedAssetIfNeeded() {
        guard
            !sendableAssets.contains(selectedAsset),
            let first = sendableAssets.first
        else { return }
        selectedAsset = first
    }

    @ViewBuilder
    private var assetPicker: some View {
        if sendableAssets.count > 1 {
            Menu {
                Picker(
                    selection: $selectedAsset,
                    label: Text(.Dashboard.sendAssetMenuLabel)
                ) {
                    ForEach(sendableAssets, id: \.self) { asset in
                        Text(viewModel.symbol(for: asset)).tag(asset)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedSymbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.tertiaryText)
                        .frame(width: 80, alignment: .trailing)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .disabled(isBusy)
        } else {
            Text(selectedSymbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private func submit(amount: Decimal) async {
        let recipient = trimmedDestination
        let success = await viewModel.send(amount: amount, to: recipient, asset: selectedAsset)
        if success { router.dismissSheet() }
    }
}
