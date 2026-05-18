//
//  VaultProgramTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 18/05/2026.
//

import CoreEntities
import Foundation
@preconcurrency import SolanaSwift
import Testing
@testable import CoreInfrastructure

@Suite("VaultProgram")
struct VaultProgramTests {
    // MARK: PDA derivations (golden vectors from `solana find-program-derived-address`)

    // Owner generated once with:
    //   solana-keygen new --no-bip39-passphrase -o /tmp/test-owner.json
    // PDAs computed with:
    //   solana find-program-derived-address ZNGuM6D1ybQSpBKDobez8Rq6TQ14FoE1tkCVCeh5gNs \
    //       string:vault pubkey:E4Lt8ktHduKPs3ZsnY7AQ9H6SQLtrtDsrtcDkJZNTbY
    //   solana find-program-derived-address ZNGuM6D1ybQSpBKDobez8Rq6TQ14FoE1tkCVCeh5gNs \
    //       string:token pubkey:EmXzLQoaac3oHmSPs4mojYJpNjstL2WDqAGsZCJMAm5y
    //   solana find-program-derived-address ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL \
    //       pubkey:E4Lt8ktHduKPs3ZsnY7AQ9H6SQLtrtDsrtcDkJZNTbY \
    //       pubkey:TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA \
    //       pubkey:666gTuw7LC1auGbivZh1834HFquTHD5DwVtiR1jQv82E
    private static let knownOwner: Pubkey = "E4Lt8ktHduKPs3ZsnY7AQ9H6SQLtrtDsrtcDkJZNTbY"
    private static let expectedVaultPDA = "EmXzLQoaac3oHmSPs4mojYJpNjstL2WDqAGsZCJMAm5y"
    private static let expectedTokenPDA = "846M1zYJWaHPoYNXNJQojgAN3Tis11UKjGGXHTU6Jebg"
    private static let expectedPayerATA = "CYVx2f9UakbvL88QMumsf6JoMvcxLNMJEdoy6ba4K4jZ"

    @Test
    func `statePDA returns golden vault PDA for known owner`() throws {
        let pda = try VaultProgram.statePDA(for: Self.knownOwner)
        #expect(pda.base58EncodedString == Self.expectedVaultPDA)
    }

    @Test
    func `tokenAccountPDA returns golden token PDA for known owner`() throws {
        let pda = try VaultProgram.tokenAccountPDA(for: Self.knownOwner)
        #expect(pda.base58EncodedString == Self.expectedTokenPDA)
    }

    @Test
    func `statePDA throws on invalid base58 owner`() {
        #expect(throws: (any Error).self) {
            try VaultProgram.statePDA(for: "not_a_valid_pubkey")
        }
    }

    // MARK: initializeAccounts identity

    @Test
    func `initializeAccounts returns the five expected accounts in order`() throws {
        let accounts = try VaultProgram.initializeAccounts(owner: Self.knownOwner)
        #expect(accounts.payer.base58EncodedString == Self.knownOwner)
        #expect(accounts.vault.base58EncodedString == Self.expectedVaultPDA)
        #expect(accounts.tokenAccount.base58EncodedString == Self.expectedTokenPDA)
        #expect(accounts.mint.base58EncodedString == VLT.mint)
        #expect(accounts.programId.base58EncodedString == VaultProgram.id)
    }

    // MARK: initializeInstruction ABI layout

    @Test
    func `initializeInstruction layout matches the 6-account ABI`() throws {
        let instruction = try VaultProgram.initializeInstruction(owner: Self.knownOwner)
        #expect(instruction.programId.base58EncodedString == VaultProgram.id)
        #expect(instruction.keys.count == 6)

        let payer = instruction.keys[0]
        #expect(payer.publicKey.base58EncodedString == Self.knownOwner)
        #expect(payer.isSigner)
        #expect(payer.isWritable)

        let vault = instruction.keys[1]
        #expect(vault.publicKey.base58EncodedString == Self.expectedVaultPDA)
        #expect(!vault.isSigner)
        #expect(vault.isWritable)

        let tokenAccount = instruction.keys[2]
        #expect(tokenAccount.publicKey.base58EncodedString == Self.expectedTokenPDA)
        #expect(!tokenAccount.isSigner)
        #expect(tokenAccount.isWritable)

        let mint = instruction.keys[3]
        #expect(mint.publicKey.base58EncodedString == VLT.mint)
        #expect(!mint.isSigner)
        #expect(!mint.isWritable)

        let tokenProgramId = instruction.keys[4]
        #expect(tokenProgramId.publicKey == TokenProgram.id)
        #expect(!tokenProgramId.isSigner)
        #expect(!tokenProgramId.isWritable)

        let systemProgramId = instruction.keys[5]
        #expect(systemProgramId.publicKey == SystemProgram.id)
        #expect(!systemProgramId.isSigner)
        #expect(!systemProgramId.isWritable)
    }

    @Test
    func `initializeInstruction data is the 8-byte initialize discriminator`() throws {
        let instruction = try VaultProgram.initializeInstruction(owner: Self.knownOwner)
        let expected = Data([175, 175, 109, 31, 13, 152, 155, 237])
        #expect(Data(instruction.data) == expected)
    }

    @Test
    func `encodeInitializeInstruction returns the 8-byte initialize discriminator`() {
        let expected = Data([175, 175, 109, 31, 13, 152, 155, 237])
        #expect(VaultProgram.encodeInitializeInstruction() == expected)
    }

    // MARK: instructionAccounts identity

    @Test
    func `instructionAccounts returns the six expected accounts in order`() throws {
        let accounts = try VaultProgram.instructionAccounts(owner: Self.knownOwner)
        #expect(accounts.payer.base58EncodedString == Self.knownOwner)
        #expect(accounts.vault.base58EncodedString == Self.expectedVaultPDA)
        #expect(accounts.mint.base58EncodedString == VLT.mint)
        #expect(accounts.payerTokenAccount.base58EncodedString == Self.expectedPayerATA)
        #expect(accounts.vaultTokenAccount.base58EncodedString == Self.expectedTokenPDA)
        #expect(accounts.programId.base58EncodedString == VaultProgram.id)
    }

    // MARK: depositInstruction / withdrawInstruction ABI layout

    @Test
    func `depositInstruction layout matches the 6-account ABI`() throws {
        let instruction = try VaultProgram.depositInstruction(owner: Self.knownOwner, amount: Decimal(1))
        assertVaultABILayout(instruction)
    }

    @Test
    func `withdrawInstruction layout matches the 6-account ABI`() throws {
        let instruction = try VaultProgram.withdrawInstruction(owner: Self.knownOwner, amount: Decimal(1))
        assertVaultABILayout(instruction)
    }

    @Test
    func `depositInstruction data is encodeAmountInstruction with scaled amount`() throws {
        let oneAndAHalf = Decimal(string: "1.5", locale: Locale(identifier: "en_US_POSIX"))
        let instruction = try VaultProgram.depositInstruction(owner: Self.knownOwner, amount: #require(oneAndAHalf))
        let expected = VaultProgram.encodeAmountInstruction(name: "deposit", amount: 1_500_000_000)
        #expect(Data(instruction.data) == expected)
    }

    @Test
    func `withdrawInstruction data is encodeAmountInstruction with scaled amount`() throws {
        let instruction = try VaultProgram.withdrawInstruction(owner: Self.knownOwner, amount: Decimal(2))
        let expected = VaultProgram.encodeAmountInstruction(name: "withdraw", amount: 2_000_000_000)
        #expect(Data(instruction.data) == expected)
    }

    private func assertVaultABILayout(_ instruction: TransactionInstruction) {
        #expect(instruction.programId.base58EncodedString == VaultProgram.id)
        #expect(instruction.keys.count == 6)

        let payer = instruction.keys[0]
        #expect(payer.publicKey.base58EncodedString == Self.knownOwner)
        #expect(payer.isSigner)
        #expect(payer.isWritable)

        let vault = instruction.keys[1]
        #expect(vault.publicKey.base58EncodedString == Self.expectedVaultPDA)
        #expect(!vault.isSigner)
        #expect(!vault.isWritable)

        let mint = instruction.keys[2]
        #expect(mint.publicKey.base58EncodedString == VLT.mint)
        #expect(!mint.isSigner)
        #expect(!mint.isWritable)

        let payerTokenAccount = instruction.keys[3]
        #expect(payerTokenAccount.publicKey.base58EncodedString == Self.expectedPayerATA)
        #expect(!payerTokenAccount.isSigner)
        #expect(payerTokenAccount.isWritable)

        let vaultTokenAccount = instruction.keys[4]
        #expect(vaultTokenAccount.publicKey.base58EncodedString == Self.expectedTokenPDA)
        #expect(!vaultTokenAccount.isSigner)
        #expect(vaultTokenAccount.isWritable)

        let tokenProgramId = instruction.keys[5]
        #expect(tokenProgramId.publicKey == TokenProgram.id)
        #expect(!tokenProgramId.isSigner)
        #expect(!tokenProgramId.isWritable)
    }

    // MARK: Encode deposit

    @Test
    func `encodeAmountInstruction deposit with amount 1000 produces discriminator plus u64 little-endian`() {
        // 1000 == 0x3E8 → little-endian bytes: E8 03 00 00 00 00 00 00
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 1000) == expected)
    }

    @Test
    func `encodeAmountInstruction deposit with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0x00, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 0) == expected)
    }

    @Test
    func `encodeAmountInstruction deposit with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
            + Data(repeating: 0xFF, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: UInt64.max) == expected)
    }

    @Test
    func `encodeAmountInstruction total layout is 16 bytes`() {
        #expect(VaultProgram.encodeAmountInstruction(name: "deposit", amount: 1000).count == 16)
    }

    // MARK: Encode withdraw

    @Test
    func `encodeAmountInstruction withdraw with amount 1000 produces discriminator plus u64 little-endian`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data([0xE8, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: 1000) == expected)
    }

    @Test
    func `encodeAmountInstruction withdraw with zero amount produces discriminator plus eight zero bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0x00, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: 0) == expected)
    }

    @Test
    func `encodeAmountInstruction withdraw with UInt64 max produces discriminator plus eight 0xFF bytes`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
            + Data(repeating: 0xFF, count: 8)
        #expect(VaultProgram.encodeAmountInstruction(name: "withdraw", amount: UInt64.max) == expected)
    }

    // MARK: Decode instruction

    @Test
    func `decodeInstruction round-trips a deposit`() throws {
        let amount: UInt64 = 5_000_000
        let data = VaultProgram.encodeAmountInstruction(name: "deposit", amount: amount)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .deposit)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeInstruction round-trips a withdraw`() throws {
        let amount: UInt64 = 12
        let data = VaultProgram.encodeAmountInstruction(name: "withdraw", amount: amount)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == amount)
    }

    @Test
    func `decodeInstruction round-trips UInt64 max as withdraw`() throws {
        let data = VaultProgram.encodeAmountInstruction(name: "withdraw", amount: UInt64.max)
        let decoded = try VaultProgram.decodeInstruction(data)
        #expect(decoded.kind == .withdraw)
        #expect(decoded.amount == UInt64.max)
    }

    @Test
    func `decodeInstruction rejects unknown discriminator`() {
        let bogus = Data(repeating: 0xAA, count: 16)
        #expect(throws: VaultInstructionDecodingError.self) {
            try VaultProgram.decodeInstruction(bogus)
        }
    }

    @Test
    func `decodeInstruction rejects payload shorter than 16 bytes`() {
        let short = Data(repeating: 0x00, count: 10)
        #expect(throws: VaultInstructionDecodingError.invalidInputData) {
            try VaultProgram.decodeInstruction(short)
        }
    }
}
