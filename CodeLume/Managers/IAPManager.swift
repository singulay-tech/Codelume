import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var creditPackages: [CreditPackageTable] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var lastErrorMessage: String?

    private let supabase = SupabaseManager.shared
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactionUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadCreditProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let packages = try await supabase.getCreditPackages()
            creditPackages = packages

            let productIds = packages.map(\.productId)
            if productIds.isEmpty {
                products = []
                return
            }

            let loadedProducts = try await Product.products(for: productIds)
            products = loadedProducts.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchase(product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                _ = try await supabase.verifyIAPPurchase(
                    productId: transaction.productID,
                    transactionId: String(transaction.id),
                    originalTransactionId: String(transaction.originalID)
                )
                await transaction.finish()
                lastErrorMessage = nil
                return true
            case .pending:
                lastErrorMessage = "Purchase is pending approval."
                return false
            case .userCancelled:
                return false
            @unknown default:
                lastErrorMessage = "Unknown purchase result."
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task {
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try checkVerified(verificationResult)
                    _ = try await supabase.verifyIAPPurchase(
                        productId: transaction.productID,
                        transactionId: String(transaction.id),
                        originalTransactionId: String(transaction.originalID)
                    )
                    await transaction.finish()
                } catch {
                    lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func checkVerified<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .unverified:
            throw NSError(domain: "IAP", code: 401, userInfo: [NSLocalizedDescriptionKey: "Purchase verification failed"])
        case .verified(let signedType):
            return signedType
        }
    }
}
