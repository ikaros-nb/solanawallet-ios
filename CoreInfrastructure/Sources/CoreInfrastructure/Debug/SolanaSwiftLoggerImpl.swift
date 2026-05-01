//
//  SolanaSwiftLoggerImpl.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 30/04/2026.
//

#if DEBUG
import os
import SolanaSwift

struct SolanaSwiftLoggerImpl: SolanaSwiftLogger {
    private static let logger = AppLog.logger(for: "SolanaSwift")

    func log(event: String, data: String?, logLevel: SolanaSwiftLoggerLogLevel) {
        let message = data.map { "[\(event)] \($0)" } ?? "[\(event)]"
        switch logLevel {
        case .debug: Self.logger.debug("\(message, privacy: .public)")
        case .info: Self.logger.info("\(message, privacy: .public)")
        case .warning: Self.logger.warning("\(message, privacy: .public)")
        case .error: Self.logger.error("\(message, privacy: .public)")
        }
    }
}
#endif
