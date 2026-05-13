//
//  VaultView.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 07/05/2026.
//

import CoreDomain
import CoreEntities
import CoreUI
import SwiftUI

struct VaultView: View {
    @State var viewModel: VaultViewModel

    var body: some View {
        Image(systemName: "lock")
    }
}

#Preview {
    VaultView(
        viewModel: VaultViewModel(owner: "PreviewOwner", walletReader: PreviewWalletReader())
    )
}

private struct PreviewWalletReader: WalletReader {
    nonisolated func fetchBalance(for _: Pubkey) async throws -> Lamports {
        42_997_949_729
    }

    nonisolated func fetchTokenAccounts(for _: Pubkey) async throws -> [SPLTokenAccount] {
        [
            SPLTokenAccount(
                mint: "666gTuw7LC1auGbivZh1834HFquTHD5DwVtiR1jQv82E",
                address: "PreviewVLTAccount",
                amount: 4_200_000_000,
                decimals: 9,
                name: "Vault Token",
                symbol: "VLT"
            ),
            SPLTokenAccount(
                mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8GVEsLuT5wgF8Dt1v",
                address: "PreviewUSDCAccount",
                amount: 1_500_000,
                decimals: 6,
                name: "USD Coin",
                symbol: "USDC"
            ),
            SPLTokenAccount(
                mint: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
                address: "PreviewBONKAccount",
                amount: 12_345_678_900,
                decimals: 5,
                name: "Bonk",
                symbol: "BONK"
            )
        ]
    }
}
