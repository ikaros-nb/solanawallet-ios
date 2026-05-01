//
//  AppDependencies.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 30/04/2026.
//

import Foundation
@preconcurrency import SolanaSwift

/// Composition root — work in progress (S18, ADR-003 D6).
///
/// Current scope : wires the SolanaSwift logger + intercepted
/// `NetworkManager` (DEBUG only) and exposes a raw `SolanaAPIClient` so the
/// logger can be smoke-tested before `SolanaClient` has any working RPC method.
///
/// TODO (S18 — open):
///  - Wire `SecureEnclaveManager` + `KeychainWalletStore`
///  - Wire `WalletProvisioner`
///  - Wire `SolanaClient` and stop exposing the raw `SolanaAPIClient`
public struct AppDependencies: Sendable {
    public let solanaAPIClient: SolanaAPIClient

    public static func make() -> AppDependencies {
        configureSolanaSwiftDebugLogging()

        let endpoint = APIEndPoint(
            address: rpcEndpoint(),
            network: .devnet
        )
        let apiClient = JSONRPCAPIClient(
            endpoint: endpoint,
            networkManager: makeNetworkManager()
        )

        return AppDependencies(solanaAPIClient: apiClient)
    }

    private static func rpcEndpoint() -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "SolanaRpcEndpoint") as? String,
            !value.isEmpty
        else {
            fatalError("SolanaRpcEndpoint missing from Info.plist — check SOLANA_RPC_ENDPOINT in xcconfig.")
        }
        return value
    }

    private static func makeNetworkManager() -> NetworkManager {
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
