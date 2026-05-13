import CoreDomain
import SwiftUI

public extension EnvironmentValues {
    @Entry var walletReader: (any WalletReader)?
}
