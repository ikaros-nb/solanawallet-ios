//
//  SolanaAPIClient+Blockhash.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import Foundation
@preconcurrency import SolanaSwift

private struct LatestBlockhashResponse: Decodable {
    struct Value: Decodable { let blockhash: String }
    let value: Value
}

extension SolanaAPIClient {
    func getLatestBlockhash(commitment: Commitment) async throws -> String {
        let response: LatestBlockhashResponse = try await request(
            method: "getLatestBlockhash",
            params: [["commitment": commitment]]
        )
        return response.value.blockhash
    }
}
