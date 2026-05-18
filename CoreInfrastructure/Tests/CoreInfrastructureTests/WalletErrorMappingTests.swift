//
//  WalletErrorMappingTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 30/04/2026.
//

import CoreDomain
import Foundation
@preconcurrency import SolanaSwift
import Testing
@testable import CoreInfrastructure

@Suite("WalletErrorMapping")
struct WalletErrorMappingTests {
    @Test
    func `url error timeout maps to network unavailable`() {
        let err = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        #expect(mapToWalletError(err) == .networkUnavailable)
    }

    @Test
    func `cannot connect maps to node unreachable`() {
        let err = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost)
        #expect(mapToWalletError(err) == .nodeUnreachable)
    }

    @Test
    func `unknown error is preserved`() {
        struct Random: Error {}
        if case let .unknown(underlying) = mapToWalletError(Random()) {
            #expect(underlying.contains("Random"))
        } else {
            Issue.record("expected .unknown")
        }
    }

    @Test
    func `wallet error is passed through unchanged`() {
        let original = WalletError.vaultError(code: 6000, message: "vault closed")
        #expect(mapToWalletError(original) == original)
    }

    @Test
    func `blockhashNotFound maps to transactionExpired`() {
        #expect(mapToWalletError(APIClientError.blockhashNotFound) == .transactionExpired)
    }

    @Test
    func `simulation logs with insufficient lamports map to insufficientSOL`() {
        let error = APIClientError.transactionSimulationError(
            logs: ["Transfer: insufficient lamports 0, need 5000"]
        )
        #expect(mapToWalletError(error) == .insufficientSOL)
    }

    @Test
    func `simulation logs without known phrase map to vaultError with last log`() {
        let error = APIClientError.transactionSimulationError(
            logs: ["Program X invoke [1]", "Program X failed: custom program error: 0x1"]
        )
        #expect(
            mapToWalletError(error)
                == .vaultError(code: -32002, message: "Program X failed: custom program error: 0x1")
        )
    }

    @Test
    func `response error -32002 with blockhash message maps to transactionExpired`() {
        let response = ResponseError(code: -32002, message: "Blockhash not found", data: nil)
        #expect(mapToWalletError(APIClientError.responseError(response)) == .transactionExpired)
    }

    @Test
    func `response error -32002 with other message maps to vaultError`() {
        let response = ResponseError(
            code: -32002,
            message: "transaction simulation failed",
            data: nil
        )
        #expect(
            mapToWalletError(APIClientError.responseError(response))
                == .vaultError(code: -32002, message: "transaction simulation failed")
        )
    }

    @Test
    func `response error -32003 maps to signingFailed`() {
        let response = ResponseError(code: -32003, message: nil, data: nil)
        #expect(mapToWalletError(APIClientError.responseError(response)) == .signingFailed)
    }

    @Test
    func `response error -32005 maps to nodeUnreachable`() {
        let response = ResponseError(code: -32005, message: "Node is behind", data: nil)
        #expect(mapToWalletError(APIClientError.responseError(response)) == .nodeUnreachable)
    }

    @Test
    func `response error -32602 maps to vaultError preserving code and message`() {
        let response = ResponseError(code: -32602, message: "invalid params", data: nil)
        #expect(
            mapToWalletError(APIClientError.responseError(response))
                == .vaultError(code: -32602, message: "invalid params")
        )
    }

    @Test
    func `couldNotRetrieveAccountInfo maps to vaultError with descriptive message`() {
        #expect(
            mapToWalletError(APIClientError.couldNotRetrieveAccountInfo)
                == .vaultError(code: 0, message: "account not found")
        )
    }
}
