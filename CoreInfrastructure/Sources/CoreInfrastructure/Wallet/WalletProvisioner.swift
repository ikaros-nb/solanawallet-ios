//
//  WalletProvisioner.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 01/05/2026.
//

import CoreDomain
import CoreEntities
import SolanaSwift

public actor WalletProvisioner: WalletCreator {
    private let keychain: KeychainWalletStore
    private let secureEnclave: SecureEnclaveManager
    private let network: SolanaNetwork

    init(
        keychain: KeychainWalletStore,
        secureEnclave: SecureEnclaveManager,
        network: SolanaNetwork
    ) {
        self.keychain = keychain
        self.secureEnclave = secureEnclave
        self.network = network
    }

    public func createWallet() async throws -> WalletCreationResult {
        // 1. Générer Account via solana-swift (mnemonic 12 mots + Ed25519)
        // 2. Récupérer privateKey bytes + publicKey + phrase
        // 3. secureEnclave.encrypt(privateKey) -> blob
        // 4. keychain.store(encryptedKeypair: blob, publicKey: ...)
        // 5. Retourner WalletCreationResult(account, seedPhrase)
        WalletCreationResult(account: <#T##WalletAccount#>, seedPhrase: <#T##String#>)
    }

    public func importWallet(seedPhrase: String) async throws -> WalletAccount {
        // 1. Trim + lowercase
        // 2. Tenter Account(phrase: words, network: network, derivablePath: .default)
        //    → catch et map vers WalletError.invalidSeedPhrase
        // 3. Encrypt + store identique à createWallet
        // 4. Retourner WalletAccount
        WalletAccount(pubkey: <#T##Pubkey#>)
    }
}
