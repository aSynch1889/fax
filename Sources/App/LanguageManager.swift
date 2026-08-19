import Foundation
import SwiftUI

/// Languages available for in-app selection.
/// Raw values match the `.lproj` folder names inside the app bundle.
public enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"

    public var id: String { rawValue }

    /// Language pickers conventionally render each option in its own language.
    public var displayName: String {
        switch self {
        case .system: return L10n.s("language_follow_system")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    /// Locale identifier for the language; nil means "follow the system".
    public var localeIdentifier: String? {
        switch self {
        case .system: return nil
        default: return rawValue
        }
    }

    /// Reads the persisted preference without touching main-actor state,
    /// so it is safe to call from any thread (e.g. PDF rendering).
    public static var stored: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: LanguageManager.storageKey) ?? ""
        return AppLanguage(rawValue: raw) ?? .system
    }
}

/// Owns the in-app language selection and publishes changes so the whole
/// view tree re-resolves localized strings immediately (no restart needed).
@MainActor
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    static let storageKey = "AppLanguagePreference"

    @Published public var current: AppLanguage {
        didSet { persist(current) }
    }

    /// Locale injected into the SwiftUI environment at the app root.
    public var locale: Locale {
        if let identifier = current.localeIdentifier {
            return Locale(identifier: identifier)
        }
        return Locale.current
    }

    init() {
        current = AppLanguage.stored
    }

    private func persist(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        // Mirror the choice into AppleLanguages so Foundation-level lookups
        // (bundle preferred localizations, date/number formatters) follow along.
        if let identifier = language.localeIdentifier {
            UserDefaults.standard.set([identifier], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }
}

/// Resolves `String`-based localized text against the user-selected language,
/// giving non-SwiftUI call sites (alerts, PDF generation, services) the same
/// instant switching behavior that `Text("key")` gets from the environment locale.
public enum L10n {
    /// Bundle for the currently selected language; main bundle when following the system.
    public static var bundle: Bundle {
        if let identifier = AppLanguage.stored.localeIdentifier,
           let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return langBundle
        }
        return .main
    }

    public static func s(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
