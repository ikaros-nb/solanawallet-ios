//
//  SOL.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 12/05/2026.
//

public enum SOL {
    public static let lamportsPerSOL: Lamports = 1_000_000_000

    public static func toSOL(_ lamports: Lamports) -> Double {
        Double(lamports) / Double(lamportsPerSOL)
    }
}
