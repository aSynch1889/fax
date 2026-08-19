import SwiftUI

@main
struct FaxApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var store = StoreManager.shared
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Propagates the in-app language selection to every Text("key") lookup.
                .environment(\.locale, languageManager.locale)
                .environmentObject(storage)
                .environmentObject(store)
        }
    }
}
