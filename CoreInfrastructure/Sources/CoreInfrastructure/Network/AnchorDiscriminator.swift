//
//  AnchorDiscriminator.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 04/05/2026.
//

import CryptoKit
import Foundation

/// Anchor-universal SHA256 discriminator primitives, shared by every on-chain
/// Anchor program. Program-specific instruction/account decoding (and its
/// errors) lives next to each program's ABI surface, not here.
public enum AnchorDiscriminator {
    public static func instructionDiscriminator(name: String) -> Data {
        discriminator(prefix: "global", name: name)
    }

    public static func accountDiscriminator(name: String) -> Data {
        discriminator(prefix: "account", name: name)
    }

    // MARK: Private

    private static func discriminator(prefix: String, name: String) -> Data {
        let payload = Data("\(prefix):\(name)".utf8)
        let digest = SHA256.hash(data: payload)
        return Data(digest.prefix(discriminatorLength))
    }

    private static let discriminatorLength = 8
}
