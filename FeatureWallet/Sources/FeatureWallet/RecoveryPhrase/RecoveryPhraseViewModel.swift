//
//  RecoveryPhraseViewModel.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreDomain
import CoreEntities
import SwiftUI
import UIKit

enum RecoveryPhraseContent {
    case create(Create)
    case importViaBIP39(Import)

    struct Create {
        let logo: String = "checkmark.shield"
        let title: LocalizedStringResource = .RecoveryPhrase.createTitle
        let description: LocalizedStringResource = .RecoveryPhrase.createDescription
        let footer: LocalizedStringResource = .RecoveryPhrase.createFooter
        let buttonTitle: LocalizedStringResource = .RecoveryPhrase.buttonPhraseSaved
    }

    struct Import {
        let logo: String = "tray.and.arrow.down"
        let title: LocalizedStringResource = .RecoveryPhrase.importTitle
        let description: LocalizedStringResource = .RecoveryPhrase.importDescription
        let footer: LocalizedStringResource = .RecoveryPhrase.importFooter
        let buttonTitle: LocalizedStringResource = .RecoveryPhrase.buttonImportWallet
        let placeholder: LocalizedStringResource = .RecoveryPhrase.importPlaceholder
        let clipboard: LocalizedStringResource = .RecoveryPhrase.importClipboard
    }
}

@Observable
@MainActor
final class RecoveryPhraseViewModel {
    let words: [String]
    let content: RecoveryPhraseContent
    var importedPhrase: String = "" {
        didSet { importError = nil }
    }

    var importError: LocalizedStringResource?
    var isImporting: Bool = false

    private let session: OnboardingSession
    private let walletCreator: (any WalletCreator)?
    private let onComplete: ((WalletAccount) -> Void)?

    init(
        mode: WalletMode,
        session: OnboardingSession,
        walletCreator: (any WalletCreator)?,
        onComplete: ((WalletAccount) -> Void)?
    ) {
        content = switch mode {
        case .create: .create(.init())
        case .importViaBIP39: .importViaBIP39(.init())
        }
        self.session = session
        self.walletCreator = walletCreator
        self.onComplete = onComplete
        words = session.seedPhrase?.read() ?? []
    }

    func createWallet(router: RecoveryPhraseRouter) {
        UIPasteboard.general.string = words.joined(separator: " ")
        router.present(.confirmation)
    }

    func confirmCreation(router: RecoveryPhraseRouter) async {
        guard let walletCreator, let seedPhrase = session.seedPhrase else {
            router.dismissSheet()
            return
        }

        do {
            let account = try await walletCreator.createWallet(seedPhrase: seedPhrase)
            session.clear()
            router.dismissSheet()
            onComplete?(account)
        } catch {
            print("Failed to create wallet: \(error)")
            router.dismissSheet()
        }
    }

    func pasteFromClipboard() {
        importedPhrase = UIPasteboard.general.string ?? importedPhrase
    }

    func importWallet() async {
        guard let walletCreator else { return }
        importError = nil
        isImporting = true
        defer { isImporting = false }
        do {
            let account = try await walletCreator.importWallet(seedPhrase: importedPhrase)
            session.clear()
            onComplete?(account)
        } catch WalletError.invalidSeedPhrase {
            importError = .RecoveryPhrase.importErrorInvalidPhrase
        } catch {
            importError = .RecoveryPhrase.importErrorGeneric
        }
    }
}
