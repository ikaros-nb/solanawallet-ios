//
//  TokenBalanceReader.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 14/05/2026.
//

import CoreEntities
import Foundation

public protocol TokenBalanceReader: Sendable {
    func fetchTokenBalance(for owner: Pubkey, mint: Pubkey) async throws -> Decimal
}
