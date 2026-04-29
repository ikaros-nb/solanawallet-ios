//
//  URLOpener.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import Foundation
import UIKit

public protocol URLOpener: Sendable {
    func canOpen(_ url: URL) async -> Bool
}

public struct SystemURLOpener: URLOpener {
    public init() {}
    public func canOpen(_ url: URL) async -> Bool {
        await MainActor.run { UIApplication.shared.canOpenURL(url) }
    }
}
