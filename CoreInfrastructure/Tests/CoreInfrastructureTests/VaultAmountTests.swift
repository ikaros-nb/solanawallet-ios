//
//  VaultAmountTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift
import Testing
@testable import CoreInfrastructure

@Suite("VaultAmount")
struct VaultAmountTests {
    // MARK: scale — happy path

    @Test
    func `scale of 1 returns 1_000_000_000`() throws {
        #expect(try VaultAmount.scale(Decimal(1)) == 1_000_000_000)
    }

    @Test
    func `scale of 1 point 5 returns 1_500_000_000`() throws {
        let oneAndAHalf = Decimal(string: "1.5", locale: Locale(identifier: "en_US_POSIX"))
        #expect(try VaultAmount.scale(#require(oneAndAHalf)) == 1_500_000_000)
    }

    // MARK: scale — rejections

    @Test
    func `scale rejects zero`() {
        #expect(throws: WalletError.vaultError(code: 6001, message: "amount must be greater than zero")) {
            try VaultAmount.scale(Decimal(0))
        }
    }

    @Test
    func `scale rejects negative`() {
        #expect(throws: WalletError.vaultError(code: 6001, message: "amount must be greater than zero")) {
            try VaultAmount.scale(Decimal(-1))
        }
    }

    // MARK: scale — round-down policy

    @Test
    func `scale of 1.0000000009 rounds down to 1_000_000_000`() throws {
        // 1.0000000009 × 10^9 = 1_000_000_000.9 → NSDecimalRound(.down) → 1_000_000_000
        // Locks in the truncation-toward-zero policy: rounding *up* would over-debit a user
        // by 1 lamport-equivalent on every fractional deposit.
        let value = Decimal(string: "1.0000000009", locale: Locale(identifier: "en_US_POSIX"))
        #expect(try VaultAmount.scale(#require(value)) == 1_000_000_000)
    }

    // MARK: scale — sub-precision rejection

    @Test
    func `scale rejects amount smaller than VLT precision`() throws {
        // 0.0000000001 × 10^9 = 0.1 → round down → 0 → uint64Value > 0 guard throws.
        // Without this guard, a user could "deposit" sub-precision dust and we'd send
        // a confirmed zero-amount transaction.
        let dust = try #require(Decimal(string: "0.0000000001", locale: Locale(identifier: "en_US_POSIX")))
        #expect(throws: WalletError.vaultError(code: 6001, message: "amount must be greater than zero")) {
            try VaultAmount.scale(dust)
        }
    }

    // MARK: decode — raw amount + decimals is the only source of truth

    @Test
    func `decode computes Decimal from raw amount and decimals`() throws {
        let balance = TokenAccountBalance(
            uiAmount: 1.234,
            amount: "1234000000",
            decimals: 9,
            uiAmountString: "1.234"
        )
        let expected = Decimal(string: "1.234", locale: Locale(identifier: "en_US_POSIX"))
        #expect(try VaultAmount.decode(balance) == #require(expected))
    }

    @Test
    func `decode ignores uiAmountString and trusts raw amount`() throws {
        // Even with a misleading uiAmountString ("999"), the function must return the
        // value derived from raw amount + decimals (1.5). Locks the canonicality of
        // the raw `amount` field.
        let balance = TokenAccountBalance(
            uiAmount: 999,
            amount: "1500000000",
            decimals: 9,
            uiAmountString: "999"
        )
        let expected = Decimal(string: "1.5", locale: Locale(identifier: "en_US_POSIX"))
        #expect(try VaultAmount.decode(balance) == #require(expected))
    }

    // MARK: decode — error path

    @Test
    func `decode throws when decimals is nil`() {
        let balance = TokenAccountBalance(
            uiAmount: nil,
            amount: "1500000000",
            decimals: nil,
            uiAmountString: nil
        )
        #expect(throws: WalletError.vaultError(code: 0, message: "invalid token account balance response")) {
            try VaultAmount.decode(balance)
        }
    }

    @Test
    func `decode throws when amount is not a UInt64`() {
        let balance = TokenAccountBalance(
            uiAmount: nil,
            amount: "not-a-number",
            decimals: 9,
            uiAmountString: nil
        )
        #expect(throws: WalletError.vaultError(code: 0, message: "invalid token account balance response")) {
            try VaultAmount.decode(balance)
        }
    }

    // MARK: decode — locale safety

    @Test
    func `decode is locale-immune to French-style comma in uiAmountString`() throws {
        // Foundation's `Decimal(string: "1,5", locale: <POSIX>)` silently parses as 1
        // (truncates at the comma). The previous implementation prioritised
        // uiAmountString and would return 1.0 here — a ~33% balance corruption.
        // The current implementation ignores uiAmountString entirely; the test locks
        // that invariant so a future regression that re-introduces uiAmountString
        // preference fails immediately.
        let balance = TokenAccountBalance(
            uiAmount: nil,
            amount: "1500000000",
            decimals: 9,
            uiAmountString: "1,5"
        )
        let expected = Decimal(string: "1.5", locale: Locale(identifier: "en_US_POSIX"))
        #expect(try VaultAmount.decode(balance) == #require(expected))
    }
}
