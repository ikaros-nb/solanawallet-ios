//
//  RecoveryPhraseView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import SwiftUI

struct RecoveryPhraseView: View {
    let viewModel: RecoveryPhraseViewModel
    @Environment(RecoveryPhraseRouter.self) private var router

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    RecoveryPhraseView(viewModel: RecoveryPhraseViewModel())
        .environment(RecoveryPhraseRouter(push: { _ in }))
}
