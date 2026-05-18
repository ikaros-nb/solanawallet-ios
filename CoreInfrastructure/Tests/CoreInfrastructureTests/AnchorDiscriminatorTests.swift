//
//  AnchorDiscriminatorTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 04/05/2026.
//

import Foundation
import Testing
@testable import CoreInfrastructure

@Suite("AnchorDiscriminator")
struct AnchorDiscriminatorTests {
    // MARK: Discriminators (golden vectors from idl/vault.json)

    @Test
    func `deposit instruction discriminator matches IDL`() {
        let expected = Data([242, 35, 198, 137, 82, 225, 242, 182])
        #expect(AnchorDiscriminator.instructionDiscriminator(name: "deposit") == expected)
    }

    @Test
    func `withdraw instruction discriminator matches IDL`() {
        let expected = Data([183, 18, 70, 156, 148, 109, 161, 34])
        #expect(AnchorDiscriminator.instructionDiscriminator(name: "withdraw") == expected)
    }

    @Test
    func `vaultState account discriminator matches IDL`() {
        let expected = Data([228, 196, 82, 165, 98, 210, 235, 152])
        #expect(AnchorDiscriminator.accountDiscriminator(name: "VaultState") == expected)
    }
}
