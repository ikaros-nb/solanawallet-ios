//
//  VaultDependencies.swift
//  FeatureVault
//
//  Created by Nicolas Bouème on 13/05/2026.
//

import CoreDomain
import SwiftUI

public extension EnvironmentValues {
    @Entry var vaultReader: (any VaultReader)?
    @Entry var vaultHistoryReader: (any VaultHistoryReader)?
}
