//
//  VLT.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import Foundation

public enum VLT {
    public static let mint: Pubkey = "666gTuw7LC1auGbivZh1834HFquTHD5DwVtiR1jQv82E"
    public static let decimals: UInt8 = 9
    public static let tokenName = "Vault Token"
    public static let tokenSymbol = "VLT"

    public static func format(_ amount: Decimal, sign: Bool = false) -> String {
        amount.formatted(.number
            .sign(strategy: sign ? .always() : .never)
            .precision(.fractionLength(2...6))
        )
    }
}

public enum VaultProgram {
    public static let id: Pubkey = "ZNGuM6D1ybQSpBKDobez8Rq6TQ14FoE1tkCVCeh5gNs"
    public static let vaultSeed = "vault"
    public static let tokenSeed = "token"
}
