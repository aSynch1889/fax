import SwiftUI
import LocalAuthentication

public struct SettingsView: View {
    @ObservedObject var storage = StorageManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    @State private var isFaceIDEnabled: Bool = UserDefaults.standard.bool(forKey: "UseFaceIDLock")
    @State private var showingPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Balance & Subscription Card Section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: storage.hasActiveSubscription ? "crown.fill" : "creditcard.fill")
                            .font(.system(size: 36))
                            .foregroundColor(storage.hasActiveSubscription ? .yellow : AppTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(storage.hasActiveSubscription ? "unlimited_subscription" : "credit_balance_label")
                                .font(.headline)
                            
                            if !storage.hasActiveSubscription {
                                Text(String(format: L10n.s("credits_count"), storage.availableCredits))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { showingPaywall = true }) {
                            Text(storage.hasActiveSubscription ? "manage" : "get_more_credits")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accent)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                Section(header: Text("settings_fax_management")) {
                    NavigationLink(destination: ContactsListView()) {
                        Label("contacts_title", systemImage: "person.crop.circle")
                    }
                    
                    HStack {
                        Label("dedicated_fax_number", systemImage: "phone.badge.checkmark")
                        Spacer()
                        Text("+1 (800) 555-FAX1")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("settings_security_privacy")) {
                    Toggle(isOn: $isFaceIDEnabled) {
                        Label("app_lock_biometric", systemImage: "faceid")
                    }
                    .onChange(of: isFaceIDEnabled) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "UseFaceIDLock")
                    }
                }

                Section(header: Text("settings_general")) {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack {
                            Label("settings_appearance", systemImage: "circle.lefthalf.filled")
                            Spacer()
                            Text(appearanceManager.current.displayName)
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink(destination: LanguageSettingsView()) {
                        HStack {
                            Label("settings_language", systemImage: "globe")
                            Spacer()
                            Text(languageManager.current.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("settings_legal_info")) {
                    Button(action: {
                        Task { await StoreManager.shared.restorePurchases() }
                    }) {
                        Label("restore_purchases", systemImage: "arrow.clockwise")
                    }
                    
                    Link(destination: URL(string: "https://bpmob.com/fax/privacy/")!) {
                        Label("privacy_policy", systemImage: "hand.raised.fill")
                    }
                    
                    Link(destination: URL(string: "https://bpmob.com/fax/terms/")!) {
                        Label("terms_of_use", systemImage: "doc.text.fill")
                    }
                    
                    HStack {
                        Label("app_version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(Text("tab_settings"))
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}
