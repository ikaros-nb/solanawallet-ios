//
//  Toast.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 14/05/2026.
//

import SwiftUI
import UIKit

public struct Toast: Identifiable, Sendable {
    public enum Style: Sendable {
        case success
        case warning
        case error
    }

    public let id: UUID
    public let message: LocalizedStringResource
    public let style: Style

    public init(message: LocalizedStringResource, style: Style) {
        id = UUID()
        self.message = message
        self.style = style
    }

    public static func success(_ message: LocalizedStringResource) -> Toast {
        Toast(message: message, style: .success)
    }

    public static func warning(_ message: LocalizedStringResource) -> Toast {
        Toast(message: message, style: .warning)
    }

    public static func error(_ message: LocalizedStringResource) -> Toast {
        Toast(message: message, style: .error)
    }
}

private struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
            Text(toast.message)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
        )
        .shadow(color: backgroundColor.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    private var iconName: String {
        switch toast.style {
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private var backgroundColor: Color {
        switch toast.style {
        case .success: .solanaGreen
        case .warning: .warning
        case .error: .negative
        }
    }
}

@MainActor
@Observable
public final class ToastCenter {
    public private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ toast: Toast) {
        dismissTask?.cancel()
        current = toast
        let id = toast.id
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            if self?.current?.id == id {
                self?.current = nil
            }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}

public extension View {
    func toastOverlay(_ center: ToastCenter) -> some View {
        modifier(ToastOverlayModifier(center: center))
    }
}

private struct ToastOverlayModifier: ViewModifier {
    let center: ToastCenter
    @State private var presenter = ToastWindowPresenter()

    func body(content: Content) -> some View {
        content.background {
            ToastSceneInstaller(center: center, presenter: presenter)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

private struct ToastSceneInstaller: UIViewRepresentable {
    let center: ToastCenter
    let presenter: ToastWindowPresenter

    func makeUIView(context _: Context) -> InstallerView {
        InstallerView(center: center, presenter: presenter)
    }

    func updateUIView(_: InstallerView, context _: Context) {}

    final class InstallerView: UIView {
        private let toastCenter: ToastCenter
        private let presenter: ToastWindowPresenter

        init(center: ToastCenter, presenter: ToastWindowPresenter) {
            toastCenter = center
            self.presenter = presenter
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isHidden = true
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) not supported")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let scene = window?.windowScene else { return }
            presenter.install(center: toastCenter, in: scene)
        }
    }
}

@MainActor
private final class ToastWindowPresenter {
    private var window: UIWindow?

    func install(center: ToastCenter, in scene: UIWindowScene) {
        guard window == nil else { return }

        let win = PassthroughWindow(windowScene: scene)
        win.windowLevel = UIWindow.Level.alert + 1
        win.backgroundColor = .clear

        let host = UIHostingController(rootView: ToastHost(center: center))
        host.view.backgroundColor = .clear
        win.rootViewController = host
        win.isHidden = false

        window = win
    }
}

private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        return hit === rootViewController?.view ? nil : hit
    }
}

private struct ToastHost: View {
    let center: ToastCenter

    var body: some View {
        VStack(spacing: 0) {
            if let toast = center.current {
                ToastView(toast: toast)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .onTapGesture { center.dismiss() }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.bouncy, value: center.current?.id)
    }
}
