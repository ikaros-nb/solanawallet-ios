//
//  Toast.swift
//  CorePresentation
//
//  Created by Nicolas Bouème on 14/05/2026.
//

import SwiftUI

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

public struct ToastView: View {
    let toast: Toast

    public init(toast: Toast) {
        self.toast = toast
    }

    public var body: some View {
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

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = center.current {
                    ToastView(toast: toast)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .onTapGesture { center.dismiss() }
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.bouncy, value: center.current?.id)
    }
}
