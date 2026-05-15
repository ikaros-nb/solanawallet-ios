//
//  SolanaClient+TokenBalanceReader.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 15/05/2026.
//

import CoreDomain
import CoreEntities
import Foundation

extension SolanaClient: TokenBalanceReader {
    public func fetchTokenBalance(for owner: Pubkey, mint: Pubkey) async throws -> Decimal {
        let accounts = try await fetchTokenAccounts(for: owner)
        guard let account = accounts.first(where: { $0.mint == mint }) else { return 0 }
        return Decimal(account.amount) / pow(10, Int(account.decimals))
    }
}
