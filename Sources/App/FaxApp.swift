import SwiftUI

@main
struct FaxApp: App {
    @StateObject private var storage = StorageManager.shared
    @StateObject private var store = StoreManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(storage)
                .environmentObject(store)
        }
    }
}
