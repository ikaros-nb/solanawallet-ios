//
//  DashboardViewModel.swift
//  FeatureDashboard
//
//  Created by Nicolas Bouème on 11/05/2026.
//

import CoreEntities
import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    let tokens: [SPLTokenAccount] = [
        SPLTokenAccount(
            mint: UUID().uuidString,
            address: UUID().uuidString,
            amount: 440_000,
            decimals: 9,
            name: "Hyperliquid",
            symbol: "HYPE"
        ),
        SPLTokenAccount(
            mint: UUID().uuidString,
            address: UUID().uuidString,
            amount: 4_200_000,
            decimals: 9,
            name: "Vault Token",
            symbol: "VLT"
        )
    ]
}
