import Foundation
import Combine
import StoreKit

@MainActor
public final class StoreManager: ObservableObject {
    public static let shared = StoreManager()
    
    public enum ProductID: String, CaseIterable {
        // Subscriptions
        case weekly = "com.evolly.faxflow.sub.weekly"
        case monthly = "com.evolly.faxflow.sub.monthly"
        case yearly = "com.evolly.faxflow.sub.yearly"
        
        // Consumables (Credits)
        case credits10 = "com.evolly.faxflow.credits.10"
        case credits50 = "com.evolly.faxflow.credits.50"
        case credits100 = "com.evolly.faxflow.credits.100"
    }
    
    @Published public var products: [Product] = []
    @Published public var purchasedProductIDs: Set<String> = []
    @Published public var isPurchasing: Bool = false
    @Published public var purchaseError: String?
    
    private var updatesTask: Task<Void, Never>?
    
    public init() {
        updatesTask = listenForTransactions()
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    public func requestProducts() async {
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            let loadedProducts = try await Product.products(for: productIDs)
            self.products = loadedProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }
    
    public func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleSuccessTransaction(transaction, for: product)
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }
    
    public func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
    
    private func handleSuccessTransaction(_ transaction: StoreKit.Transaction, for product: Product) async {
        if product.type == .autoRenewable || product.type == .nonRenewable {
            purchasedProductIDs.insert(product.id)
            StorageManager.shared.setSubscriptionActive(true)
        } else if product.type == .consumable {
            switch product.id {
            case ProductID.credits10.rawValue:
                StorageManager.shared.addCredits(10)
            case ProductID.credits50.rawValue:
                StorageManager.shared.addCredits(50)
            case ProductID.credits100.rawValue:
                StorageManager.shared.addCredits(100)
            default:
                break
            }
        }
    }
    
    public func updatePurchasedProducts() async {
        var activeIDs = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    activeIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed entitlement verification: \(error)")
            }
        }
        self.purchasedProductIDs = activeIDs
        let isSubscribed = activeIDs.contains(where: {
            $0 == ProductID.weekly.rawValue || $0 == ProductID.monthly.rawValue || $0 == ProductID.yearly.rawValue
        })
        StorageManager.shared.setSubscriptionActive(isSubscribed)
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction update verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
