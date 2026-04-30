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
        let bodyPreview = request.httpBody
            .flatMap { String(data: $0.prefix(Self.bodyPreviewLimit), encoding: .utf8) } ?? ""
        Self.logger.debug("→ \(method, privacy: .public) \(url, privacy: .public) \(bodyPreview, privacy: .public)")

        let start = Date()
        do {
            let data = try await wrapped.requestData(request: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let preview = String(data: data.prefix(Self.bodyPreviewLimit), encoding: .utf8) ?? "<binary>"
            Self.logger
                .debug("← \(ms, privacy: .public)ms \(data.count, privacy: .public)B \(preview, privacy: .public)")
            return data
        } catch {
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            Self.logger.error("✗ \(ms, privacy: .public)ms \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
#endif
