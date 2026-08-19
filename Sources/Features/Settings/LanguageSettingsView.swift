import SwiftUI

/// Second-level settings page for in-app language selection.
/// Tapping an option applies the language immediately across the whole app.
public struct LanguageSettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        languageManager.current = language
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if languageManager.current == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                }
            } footer: {
                Text("language_change_note")
            }
        }
        .navigationTitle(Text("settings_language"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
