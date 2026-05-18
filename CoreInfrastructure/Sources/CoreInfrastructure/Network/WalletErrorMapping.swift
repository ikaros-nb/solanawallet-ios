//
//  WalletErrorMapping.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import Foundation

func mapToWalletError(_ error: Error) -> WalletError {
    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
        switch nsError.code {
        case NSURLErrorCannotConnectToHost: return .nodeUnreachable
        case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut: return .networkUnavailable
        default: break
        }
    }
    // TODO: (S19) ajouter les mappings des erreurs solana-swift
    // au fur et à mesure qu'elles surfacent lors des vrais appels RPC.
    // Cible : table ADR-001 D7 (transactionExpired, insufficient*, vaultError, signingFailed)
    return .unknown(underlying: "\(error)")
}

func mapToStaleCacheError<Value>(
    _ error: Error,
    cached: Value?,
    wrap: (Value, WalletError) -> WalletError
) -> WalletError {
    let mapped = mapToWalletError(error)
    if let cached {
        return wrap(cached, mapped)
    }
    return mapped
}
