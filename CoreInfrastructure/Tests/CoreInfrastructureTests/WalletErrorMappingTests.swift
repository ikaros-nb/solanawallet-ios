//
//  WalletErrorMappingTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 30/04/2026.
//

import CoreDomain
import Foundation
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
}
