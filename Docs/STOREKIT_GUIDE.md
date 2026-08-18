# StoreKit 2 Monetization & In-App Purchase Guide

## 1. Product Identifier Catalog
- Subscriptions:
  - com.evolly.faxflow.sub.weekly: $3.99/week (3-day trial)
  - com.evolly.faxflow.sub.monthly: $9.99/month
  - com.evolly.faxflow.sub.yearly: $50.99/year (Best Value)
- Consumable Credits:
  - com.evolly.faxflow.credits.10: $4.99 (10 Pages)
  - com.evolly.faxflow.credits.50: $19.99 (50 Pages)
  - com.evolly.faxflow.credits.100: $34.99 (100 Pages)

## 2. StoreManager Workflow
1. Request Products: Product.products(for: productIDs)
2. Purchase: product.purchase() -> VerificationResult<Transaction>
3. Entitlement Verification: Transaction.currentEntitlements
4. Transaction Listener: Task listening to StoreKit.Transaction.updates
5. Restore Purchases: AppStore.sync()
