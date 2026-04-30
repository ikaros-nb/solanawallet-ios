//
//  LoggingNetworkManager.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 30/04/2026.
//

#if DEBUG
import Foundation
import os
import SolanaSwift

struct LoggingNetworkManager: NetworkManager {
    private static let logger = os.Logger(
        subsystem: "com.ikaros.SolanaWallet.coreinfrastructure",
        category: "SolanaSwift.Network"
    )
    private static let bodyPreviewLimit = 2048

    let wrapped: any NetworkManager & Sendable

    func requestData(request: URLRequest) async throws -> Data {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "<no-url>"
        let bodyPreview = request.httpBody.map { Self.formatBody($0) } ?? ""
        Self.logger.debug("→ \(method, privacy: .public) \(url, privacy: .public)\n\(bodyPreview, privacy: .public)")

        let start = Date()
        do {
            let data = try await wrapped.requestData(request: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let preview = Self.formatBody(data)
            Self.logger
                .debug("← \(ms, privacy: .public)ms \(data.count, privacy: .public)B\n\(preview, privacy: .public)")
            return data
        } catch {
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            Self.logger.error("✗ \(ms, privacy: .public)ms \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private static func formatBody(_ data: Data) -> String {
        if let pretty = prettyPrintedJSON(data) {
            return String(pretty.prefix(bodyPreviewLimit))
        }
        if let string = String(data: data, encoding: .utf8) {
            return String(string.prefix(bodyPreviewLimit))
        }
        return "<binary>"
    }

    private static func prettyPrintedJSON(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }
        guard
            let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            )
        else {
            return nil
        }
        return String(data: pretty, encoding: .utf8)
    }
}
#endif
