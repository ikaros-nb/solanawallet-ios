//
//  Dependencies.swift
//  CoreDependencies
//
//  Created by Nicolas Bouème on 14/05/2026.
//

import CoreDomain
import SwiftUI

public extension EnvironmentValues {
    @Entry var walletReader: (any WalletReader)?
    @Entry var walletCreator: (any WalletCreator)?
    @Entry var biometricAuthenticator: (any BiometricAuthenticator)?
    @Entry var vaultStateReader: (any VaultStateReader)?
    @Entry var vaultBalanceReader: (any VaultBalanceReader)?
    @Entry var vaultHistoryReader: (any VaultHistoryReader)?
    @Entry var vaultTransactor: (any VaultTransactor)?
    @Entry var tokenBalanceReader: (any TokenBalanceReader)?
    @Entry var transactionSender: (any TransactionSender)?
}
