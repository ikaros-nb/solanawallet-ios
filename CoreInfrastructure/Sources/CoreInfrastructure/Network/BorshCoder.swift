//
//  BorshCoder.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 04/05/2026.
//

import CoreEntities
import CryptoKit
import Foundation
import SolanaSwift

public enum BorshCoderError: Error, Equatable, Sendable {
    case invalidInputData
    case invalidDiscriminator(expected: Data, got: Data)
    case invalidPublicKeyBytes
}

public struct DecodedVaultInstruction: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case deposit
        case withdraw
    }

    public let kind: Kind
    public let amount: UInt64
}

public struct BorshCoder: Sendable {
    public init() {}

    public func encodeDeposit(amount: UInt64) -> Data {
        encodeInstructionData(instructionName: "deposit", amount: amount)
    }

    public func encodeWithdraw(amount: UInt64) -> Data {
        encodeInstructionData(instructionName: "withdraw", amount: amount)
    }

    public func decodeVaultInstruction(from data: Data) throws -> DecodedVaultInstruction {
        let discLen = Self.discriminatorLength
        let amountLen = MemoryLayout<UInt64>.size
        guard data.count >= discLen + amountLen else {
            throw BorshCoderError.invalidInputData
        }

        let receivedDisc = data.prefix(discLen)
        let depositDisc = Self.instructionDiscriminator(name: "deposit")
        let withdrawDisc = Self.instructionDiscriminator(name: "withdraw")

        let kind: DecodedVaultInstruction.Kind
        if receivedDisc == depositDisc {
            kind = .deposit
        } else if receivedDisc == withdrawDisc {
            kind = .withdraw
        } else {
            throw BorshCoderError.invalidDiscriminator(
                expected: depositDisc,
                got: Data(receivedDisc)
            )
        }

        let amountRange = discLen..<(discLen + amountLen)
        let amount = data[amountRange].withUnsafeBytes { raw in
            raw.loadUnaligned(as: UInt64.self)
        }.littleEndian

        return DecodedVaultInstruction(kind: kind, amount: amount)
    }

    public func decodeVaultAccount(from data: Data) throws -> VaultAccount {
        let expectedDiscriminator = Self.accountDiscriminator(name: "VaultState")
        let discriminatorLength = Self.discriminatorLength
        let pubkeyLength = Self.pubkeyLength

        let expectedSize = discriminatorLength + pubkeyLength + MemoryLayout<UInt8>.size + pubkeyLength
        guard data.count >= expectedSize else {
            throw BorshCoderError.invalidInputData
        }

        let receivedDiscriminator = data.prefix(discriminatorLength)
        guard receivedDiscriminator == expectedDiscriminator else {
            throw BorshCoderError.invalidDiscriminator(
                expected: expectedDiscriminator,
                got: Data(receivedDiscriminator)
            )
        }

        var offset = discriminatorLength

        let ownerBytes = Data(data[offset..<offset + pubkeyLength])
        offset += pubkeyLength

        let bump = data[offset]
        offset += MemoryLayout<UInt8>.size

        let mintBytes = Data(data[offset..<offset + pubkeyLength])

        guard
            let ownerPubkey: Pubkey = try? PublicKey(data: ownerBytes).base58EncodedString,
            let mintPubkey: Pubkey = try? PublicKey(data: mintBytes).base58EncodedString
        else {
            throw BorshCoderError.invalidPublicKeyBytes
        }

        return VaultAccount(owner: ownerPubkey, bump: bump, mint: mintPubkey)
    }

    public static func instructionDiscriminator(name: String) -> Data {
        discriminator(prefix: "global", name: name)
    }

    public static func accountDiscriminator(name: String) -> Data {
        discriminator(prefix: "account", name: name)
    }

    // MARK: Private

    private func encodeInstructionData(instructionName: String, amount: UInt64) -> Data {
        let discriminator = Self.instructionDiscriminator(name: instructionName)
        let amountLE = withUnsafeBytes(of: amount.littleEndian) { Data($0) }
        return discriminator + amountLE
    }

    private static func discriminator(prefix: String, name: String) -> Data {
        let payload = Data("\(prefix):\(name)".utf8)
        let digest = SHA256.hash(data: payload)
        return Data(digest.prefix(discriminatorLength))
    }

    private static let discriminatorLength = 8
    private static let pubkeyLength = 32
}
