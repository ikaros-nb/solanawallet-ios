//
//  BiometryView.swift
//  FeatureWallet
//
//  Created by Nicolas Bouème on 06/05/2026.
//

import CoreUI
import SwiftUI

struct BiometryView: View {
    let viewModel: BiometryViewModel
    @Environment(BiometryRouter.self) private var router

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Spacer()

                faceIdLogo()
                Text(.Biometry.title)
                    .typography(.title)
                Text(.Biometry.description)
                    .typography(.body)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                ActionButton(
                    title: .Biometry.buttonEnableFaceID,
                    icon: Image(systemName: "faceid"),
                    style: .primaryPurple
                ) {
                    Task {
                        await viewModel.authenticateWithFaceID(router: router)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 12)
        .background(Color.deepIndigo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(.Biometry.navigationTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    private func faceIdLogo() -> some View {
        ZStack {
            Circle()
                .fill(Color.card)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 120, height: 120)
                .shadow(color: Color.solanaGreen.opacity(0.13), radius: 80, x: 0, y: 0)
                .shadow(color: Color.solanaPurple.opacity(0.4), radius: 50, x: 0, y: 0)
            Image(systemName: "faceid")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .foregroundStyle(Color.solanaGreen)
        }
    }
}

#Preview {
    NavigationStack {
        BiometryView(
            viewModel: BiometryViewModel(
                mode: .create,
                walletCreator: nil,
                session: OnboardingSession()
            )
        )
        .environment(BiometryRouter(push: { _ in }))
    }
}
