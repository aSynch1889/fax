import Foundation
import SwiftUI

/// Appearance modes available for in-app selection.
public enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return L10n.s("appearance_follow_system")
        case .light: return L10n.s("appearance_light")
        case .dark: return L10n.s("appearance_dark")
        }
    }

    /// Color scheme injected into the SwiftUI environment at the app root;
    /// nil means "follow the system".
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Reads the persisted preference without touching main-actor state.
    public static var stored: AppAppearance {
        let raw = UserDefaults.standard.string(forKey: AppearanceManager.storageKey) ?? ""
        return AppAppearance(rawValue: raw) ?? .system
    }
}

/// Owns the in-app appearance selection and publishes changes so the whole
/// view tree re-renders in the chosen color scheme immediately (no restart needed).
@MainActor
public final class AppearanceManager: ObservableObject {
    public static let shared = AppearanceManager()
    static let storageKey = "AppAppearancePreference"

    @Published public var current: AppAppearance {
        didSet { persist(current) }
    }

    init() {
        current = AppAppearance.stored
    }

    private func persist(_ appearance: AppAppearance) {
        UserDefaults.standard.set(appearance.rawValue, forKey: Self.storageKey)
    }
}
