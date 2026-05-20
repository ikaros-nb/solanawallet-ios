//
//  QRScannerSheet.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 20/05/2026.
//

import AVFoundation
import CoreUI
import SwiftUI
import UIKit
import VisionKit

struct QRScannerSheet: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var permission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var invalidHintVisible: Bool = false
    @State private var hintResetTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            content

            chrome
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch permission {
        case .notDetermined:
            ProgressView()
                .tint(.white)
                .task { await requestAccess() }

        case .authorized:
            if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                DataScannerRepresentable(onFound: handleScan)
                    .ignoresSafeArea()
            } else {
                unavailableView
            }

        case .denied, .restricted:
            permissionDeniedView

        @unknown default:
            permissionDeniedView
        }
    }

    private var chrome: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.4), in: Circle())
                }

                Spacer()

                Text(.Dashboard.scanTitle)
                    .typography(.sheetTitle)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            if invalidHintVisible {
                Text(.Dashboard.scanInvalidAddress)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.red.opacity(0.85), in: Capsule())
                    .padding(.bottom, 48)
                    .transition(.opacity)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.6))

            Text(.Dashboard.scanPermissionDeniedTitle)
                .typography(.sheetTitle)
                .multilineTextAlignment(.center)

            Text(.Dashboard.scanPermissionDeniedBody)
                .typography(.sheetBody)
                .multilineTextAlignment(.center)

            ActionButton(
                title: .Dashboard.scanPermissionOpenSettings,
                icon: Image(systemName: "gearshape"),
                style: .primaryGreen
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    private var unavailableView: some View {
        Text(.Dashboard.scanUnavailable)
            .typography(.sheetBody)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }

    private func requestAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        permission = granted ? .authorized : .denied
    }

    private func handleScan(_ scanned: String) {
        let trimmed = scanned.trimmingCharacters(in: .whitespacesAndNewlines)
        guard SolanaAddressValidator.isStructurallyValid(trimmed) else {
            triggerInvalidHint()
            return
        }
        onScan(trimmed)
    }

    private func triggerInvalidHint() {
        hintResetTask?.cancel()
        withAnimation { invalidHintVisible = true }
        hintResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation { invalidHintVisible = false }
        }
    }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        viewController.delegate = context.coordinator
        DispatchQueue.main.async {
            try? viewController.startScanning()
        }
        return viewController
    }

    func updateUIViewController(_: DataScannerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFound: onFound)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onFound: (String) -> Void

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func dataScanner(
            _: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems _: [RecognizedItem]
        ) {
            for case let .barcode(barcode) in addedItems {
                if let payload = barcode.payloadStringValue {
                    onFound(payload)
                    return
                }
            }
        }
    }
}
