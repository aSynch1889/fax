import SwiftUI

/// Second-level settings page for in-app appearance (light/dark) selection.
/// Tapping an option applies the color scheme immediately across the whole app.
public struct AppearanceSettingsView: View {
    @ObservedObject private var appearanceManager = AppearanceManager.shared

    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        appearanceManager.current = appearance
                    } label: {
                        HStack {
                            Text(appearance.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if appearanceManager.current == appearance {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("appearance_change_note")
            }
        }
        .navigationTitle(Text("settings_appearance"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
