import SwiftUI
import StoreKit

public struct PaywallView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var store = StoreManager.shared
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedPlanIndex: Int = 0 // 0: Weekly, 1: Monthly, 2: Yearly
    @State private var selectedTab: Int = 0 // 0: Subscriptions, 1: Credits Packs
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Logo & Badge
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.blue.opacity(0.8), Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, y: 5)
                            
                            Image(systemName: "faxmachine")
                                .font(.system(size: 38))
                                .foregroundColor(.white)
                        }
                        
                        Text("paywall_title")
                            .font(.title)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("paywall_subtitle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    
                    // Tab Selector: Subscriptions vs Credits
                    Picker("options", selection: $selectedTab) {
                        Text("unlimited_subscriptions_tab").tag(0)
                        Text("credit_packs_tab").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        // Features List
                        VStack(alignment: .leading, spacing: 14) {
                            FeatureRow(icon: "bolt.shield.fill", text: "feature_fast_delivery")
                            FeatureRow(icon: "viewfinder.circle.fill", text: "feature_hd_scanner")
                            FeatureRow(icon: "signature", text: "feature_esign")
                            FeatureRow(icon: "doc.badge.checkmark", text: "feature_receipts")
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                        
                        // Subscription Cards
                        VStack(spacing: 12) {
                            PlanOptionCard(titleKey: "plan_yearly", price: String(format: L10n.s("price_per_year"), "$50.99"), subtext: L10n.s("subtext_yearly"), isSelected: selectedPlanIndex == 2) {
                                selectedPlanIndex = 2
                            }
                            
                            PlanOptionCard(titleKey: "plan_weekly", price: String(format: L10n.s("price_per_week"), "$3.99"), subtext: L10n.s("subtext_weekly"), isSelected: selectedPlanIndex == 0) {
                                selectedPlanIndex = 0
                            }
                            
                            PlanOptionCard(titleKey: "plan_monthly", price: String(format: L10n.s("price_per_month"), "$9.99"), subtext: L10n.s("subtext_monthly"), isSelected: selectedPlanIndex == 1) {
                                selectedPlanIndex = 1
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Credit Pack Cards
                        VStack(spacing: 12) {
                            CreditPackCard(titleKey: "credit_pack_100", price: "$34.99", perPage: String(format: L10n.s("price_per_page"), "$0.35"), popular: true) {
                                Task {
                                    if let p = store.products.first(where: { $0.id == StoreManager.ProductID.credits100.rawValue }) {
                                        _ = await store.purchase(p)
                                    } else {
                                        storage.addCredits(100)
                                    }
                                }
                            }
                            
                            CreditPackCard(titleKey: "credit_pack_50", price: "$19.99", perPage: String(format: L10n.s("price_per_page"), "$0.40"), popular: false) {
                                Task {
                                    if let p = store.products.first(where: { $0.id == StoreManager.ProductID.credits50.rawValue }) {
                                        _ = await store.purchase(p)
                                    } else {
                                        storage.addCredits(50)
                                    }
                                }
                            }
                            
                            CreditPackCard(titleKey: "credit_pack_10", price: "$4.99", perPage: String(format: L10n.s("price_per_page"), "$0.50"), popular: false) {
                                Task {
                                    if let p = store.products.first(where: { $0.id == StoreManager.ProductID.credits10.rawValue }) {
                                        _ = await store.purchase(p)
                                    } else {
                                        storage.addCredits(10)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Purchase CTA Button
                    if selectedTab == 0 {
                        Button(action: {
                            Task {
                                let productID = selectedPlanIndex == 0 ? StoreManager.ProductID.weekly.rawValue : (selectedPlanIndex == 1 ? StoreManager.ProductID.monthly.rawValue : StoreManager.ProductID.yearly.rawValue)
                                if let p = store.products.first(where: { $0.id == productID }) {
                                    let success = await store.purchase(p)
                                    if success { presentationMode.wrappedValue.dismiss() }
                                } else {
                                    // Fallback for screenshot / sandbox mode
                                    storage.setSubscriptionActive(true)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if store.isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("continue_button")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Footer Links
                    HStack(spacing: 20) {
                        Button("restore_purchases") {
                            Task { await store.restorePurchases() }
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Link("privacy_policy", destination: URL(string: "https://asynch1889.github.io/faxflow-privacy/privacy.html")!)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Link("terms_of_use", destination: URL(string: "https://asynch1889.github.io/faxflow-privacy/terms.html")!)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

public struct FeatureRow: View {
    public var icon: String
    public var text: LocalizedStringKey
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(AppTheme.accent)
                .frame(width: 28)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

public struct PlanOptionCard: View {
    public var titleKey: LocalizedStringKey
    public var price: String
    public var subtext: String
    public var isSelected: Bool
    public var onSelect: () -> Void
    
    public var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleKey)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtext)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? AppTheme.accent : .primary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.accent : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppTheme.accent : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.secondaryGroupBackground))
            )
        }
    }
}

public struct CreditPackCard: View {
    public var titleKey: LocalizedStringKey
    public var price: String
    public var perPage: String
    public var popular: Bool
    public var onBuy: () -> Void
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(titleKey)
                        .font(.headline)
                    if popular {
                        Text("badge_popular")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
                Text(perPage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onBuy) {
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .glassCard()
    }
}
