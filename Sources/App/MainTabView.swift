import SwiftUI

public struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var storage = StorageManager.shared
    @StateObject private var store = StoreManager.shared
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            SendFaxView()
                .tabItem {
                    Label("tab_send", systemImage: "paperplane.fill")
                }
                .tag(AppState.TabItem.send)
            
            DocumentsListView()
                .tabItem {
                    Label("tab_documents", systemImage: "folder.fill")
                }
                .tag(AppState.TabItem.documents)
            
            HistoryListView()
                .tabItem {
                    Label("tab_history", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppState.TabItem.history)
            
            SettingsView()
                .tabItem {
                    Label("tab_settings", systemImage: "gearshape.fill")
                }
                .tag(AppState.TabItem.settings)
        }
        .accentColor(AppTheme.accent)
    }
}
