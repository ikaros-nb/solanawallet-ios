//
//  WalletErrorMapping.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreDomain
import Foundation
@preconcurrency import SolanaSwift

func mapToWalletError(_ error: Error) -> WalletError {
    if let walletError = error as? WalletError { return walletError }

    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
        switch nsError.code {
        case NSURLErrorCannotConnectToHost: return .nodeUnreachable
        case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut: return .networkUnavailable
        default: break
        }
    }

    if let apiError = error as? APIClientError {
        return mapAPIClientError(apiError)
    }

    if
        let confirmError = error as? TransactionConfirmationError,
        case .unconfirmed = confirmError {
        return .transactionExpired
    }

    return .unknown(underlying: "\(error)")
}

private func mapAPIClientError(_ error: APIClientError) -> WalletError {
    switch error {
    case .blockhashNotFound:
        return .transactionExpired
    case let .transactionSimulationError(logs):
        if logs.contains(where: isInsufficientLamportsLog) {
            return .insufficientSOL
        }
        return .vaultError(code: -32002, message: logs.last ?? "simulation failed")
    case let .responseError(response):
        return mapResponseError(response)
    case .couldNotRetrieveAccountInfo:
        return .vaultError(code: 0, message: "account not found")
    case .invalidAPIURL:
        return .unknown(underlying: "RPC URL misconfigured")
    case .invalidResponse:
        return .unknown(underlying: "invalid RPC response")
    }
}

private func mapResponseError(_ response: ResponseError) -> WalletError {
    guard let code = response.code else {
        return .unknown(underlying: response.message ?? "RPC response error")
    }
    let message = response.message ?? ""
    switch code {
    case -32002:
        if message.localizedCaseInsensitiveContains("blockhash") {
            return .transactionExpired
        }
        return .vaultError(code: code, message: message)
    case -32003:
        return .signingFailed
    case -32005:
        return .nodeUnreachable
    default:
        return .vaultError(code: code, message: message)
    }
}

private func isInsufficientLamportsLog(_ log: String) -> Bool {
    log.localizedCaseInsensitiveContains("insufficient lamports")
        || log.localizedCaseInsensitiveContains("insufficientfunds")
        || log.localizedCaseInsensitiveContains("insufficient funds for instruction")
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
