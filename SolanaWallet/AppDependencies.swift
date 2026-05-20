//
//  AppDependencies.swift
//  SolanaWallet
//
//  Created by Nicolas Bouème on 30/04/2026.
//

import CoreDomain
import CoreInfrastructure
import Foundation
@preconcurrency import SolanaSwift

/// Wires the security stack (Secure Enclave + Keychain), the Solana RPC client,
/// and the wallet provisioner.
struct AppDependencies {
    let keychain: KeychainWalletStore
    let walletCreator: any WalletCreator
    let biometricAuthenticator: any BiometricAuthenticator
    let solanaClient: SolanaClient

    static func make() throws -> AppDependencies {
        configureSolanaSwiftDebugLogging()

        let secureEnclave = try SecureEnclaveManager()
        let keychain = KeychainWalletStore(secureEnclave: secureEnclave)

        let endpointAddress = solanaRpcEndpoint()
        let endpoint = APIEndPoint(
            address: endpointAddress,
            network: .devnet
        )
        let apiClient = JSONRPCAPIClient(
            endpoint: endpoint,
            networkManager: makeNetworkManager()
        )

        let tokenRepository = SolanaTokenListRepository(
            tokenListSource: SolanaTokenListSourceImpl.solanaLabs(
                networkManager: makeNetworkManager()
            )
        )

        let solanaClient = SolanaClient(
            rpc: apiClient,
            keychain: keychain,
            tokenRepository: tokenRepository
        )
        let biometricAuthenticator = LocalAuthenticationBiometricAuthenticator()
        let walletCreator = WalletProvisioner(keychain: keychain, biometric: biometricAuthenticator)

        return AppDependencies(
            keychain: keychain,
            walletCreator: walletCreator,
            biometricAuthenticator: biometricAuthenticator,
            solanaClient: solanaClient
        )
    }

    /// Reads `SolanaRpcEndpoint` from the host bundle's Info.plist (injected
    /// from `Config/{Debug,Release}.xcconfig` via `SOLANA_RPC_ENDPOINT`).
    /// Falls back to Surfpool localhost so unit tests and previews — where
    /// `Bundle.main` is the test/preview bundle — keep a usable default.
    private static func solanaRpcEndpoint() -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "SolanaRpcEndpoint") as? String,
            !value.isEmpty
        else {
            return "http://localhost:8899"
        }
        return value
    }

    private static func makeNetworkManager() -> any NetworkManager {
        #if DEBUG
        return LoggingNetworkManager(wrapped: URLSession(configuration: .default))
        #else
        return URLSession(configuration: .default)
        #endif
    }

    private static func configureSolanaSwiftDebugLogging() {
        #if DEBUG
        Logger.setLoggers([SolanaSwiftLoggerImpl()])
        #endif
    }
}
