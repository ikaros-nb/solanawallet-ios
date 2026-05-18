//
//  VaultAmount.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation
@preconcurrency import SolanaSwift

enum VaultAmount {
    static func scale(_ amount: Decimal) throws -> UInt64 {
        guard amount > 0 else {
            throw WalletError.vaultError(code: 6001, message: "amount must be greater than zero")
        }
        var scaled = amount * pow(10, Int(VLT.decimals))
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .down)
        let number = NSDecimalNumber(decimal: rounded)
        guard number.doubleValue.isFinite, number.uint64Value > 0 else {
            throw WalletError.vaultError(code: 6001, message: "amount must be greater than zero")
        }
        return number.uint64Value
    }

    static func decode(_ balance: TokenAccountBalance) throws -> Decimal {
        let uiDecimal = balance.uiAmountString.flatMap { Decimal(string: $0, locale: posix) }
        if let decimal = uiDecimal { return decimal }
        guard let rawAmount = UInt64(balance.amount), let decimals = balance.decimals else {
            throw WalletError.vaultError(code: 0, message: "invalid token account balance response")
        }
        return Decimal(rawAmount) / pow(10, Int(decimals))
    }

    private static let posix = Locale(identifier: "en_US_POSIX")
}
