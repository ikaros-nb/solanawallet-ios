//
//  LatestBlockhash.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreDomain
import Foundation

func fetchLatestBlockhash(at endpoint: URL) async throws -> String {
    struct Envelope: Decodable {
        struct Body: Decodable {
            struct Value: Decodable { let blockhash: String }
            let value: Value
        }

        struct RPCError: Decodable {
            let code: Int
            let message: String
        }

        let result: Body?
        let error: RPCError?
    }

    let payload: [String: Any] = [
        "jsonrpc": "2.0",
        "id": UUID().uuidString,
        "method": "getLatestBlockhash",
        "params": [["commitment": "confirmed"]]
    ]

    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)

    let (data, _) = try await URLSession.shared.data(for: request)
    let envelope = try JSONDecoder().decode(Envelope.self, from: data)
    if let error = envelope.error {
        throw WalletError.vaultError(code: error.code, message: error.message)
    }
    guard let blockhash = envelope.result?.value.blockhash else {
        throw WalletError.unknown(underlying: "missing blockhash in getLatestBlockhash response")
    }
    return blockhash
}
