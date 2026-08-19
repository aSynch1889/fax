import SwiftUI

@main
struct FaxApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var appearanceManager = AppearanceManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Propagates the in-app language selection to every Text("key") lookup.
                .environment(\.locale, languageManager.locale)
                // Applies the in-app appearance selection (nil = follow the system).
                .preferredColorScheme(appearanceManager.current.colorScheme)
                .environmentObject(storage)
                .environmentObject(store)
        }
    }
}
