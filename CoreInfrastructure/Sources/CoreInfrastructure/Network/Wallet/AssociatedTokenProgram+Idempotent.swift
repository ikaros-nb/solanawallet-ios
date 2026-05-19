//
//  AssociatedTokenProgram+Idempotent.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 19/05/2026.
//

@preconcurrency import SolanaSwift

extension AssociatedTokenProgram {
    /// solana-swift only ships the non-idempotent variant (discriminator 0); the idempotent
    /// variant has the same accounts but discriminator byte 1 and succeeds whether or not
    /// the ATA already exists.
    static func createIdempotentInstruction(
        associatedAccount: PublicKey,
        mint: PublicKey,
        owner: PublicKey,
        payer: PublicKey,
        tokenProgramId: PublicKey
    ) -> TransactionInstruction {
        TransactionInstruction(
            keys: [
                .init(publicKey: payer, isSigner: true, isWritable: true),
                .init(publicKey: associatedAccount, isSigner: false, isWritable: true),
                .init(publicKey: owner, isSigner: false, isWritable: false),
                .init(publicKey: mint, isSigner: false, isWritable: false),
                .init(publicKey: SystemProgram.id, isSigner: false, isWritable: false),
                .init(publicKey: tokenProgramId, isSigner: false, isWritable: false)
            ],
            programId: AssociatedTokenProgram.id,
            data: [UInt8(1)]
        )
    }
}
