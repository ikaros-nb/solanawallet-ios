//
//  AppLog.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 02/05/2026.
//

import os

/// Module-scoped logger factory. Centralises the OSLog subsystem so callsites
/// only declare a category. Lift to a shared module if Features need it.
enum AppLog {
    private static let subsystem = "com.ikaros.SolanaWallet.coreinfrastructure"

    static func logger(for category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
