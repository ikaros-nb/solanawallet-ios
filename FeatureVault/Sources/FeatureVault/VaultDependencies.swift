//
//  VaultDependencies.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreDomain
import SwiftUI

public extension EnvironmentValues {
    @Entry var vaultBalanceReader: (any VaultBalanceReader)?
    @Entry var vaultHistoryReader: (any VaultHistoryReader)?
    @Entry var vaultTransactor: (any VaultTransactor)?
}
