//
//  DSSIAPService.swift
//  DSSNetwork
//
//  Created by David on 28/03/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import StoreKit

public protocol DSSIAPProduct: CaseIterable & RawRepresentable where RawValue == String {
}

public extension Collection where Element: DSSIAPProduct {
    func map<T: Hashable>(_ transform: (Element) throws -> T) rethrows -> Set<T> {
        var set: Set<T> = Set()
        self.forEach {
            if let element = try? transform($0) { set.insert(element) }
        }
        return set
    }
}

public extension SKPaymentTransactionState {
    var description: String {
        switch self {
        case .purchasing: return "Purchasing"
        case .purchased: return "Purchased"
        case .failed: return "Failed"
        case .restored: return "Restored"
        case .deferred: return "Deferred"
        @unknown default: fatalError("Apple added a new case to SKPaymentTransactionState")
        }
    }
}

open class DSSIAPService: NSObject {
    private var request: SKProductsRequest?

    private var products: Set<SKProduct> = []

    private var paymentQueue: SKPaymentQueue { .default() }

    private var dispatchGroup: DispatchGroup?

    public func setPaymentQueueDelegate() {
        paymentQueue.add(self)
    }

    public func removePaymentQueueDelegate() {
        paymentQueue.remove(self)
    }

    public func fetch<T: DSSIAPProduct>(products: T.Type, _ completion: @escaping (Result<Set<SKProduct>, NSError>) -> Void) {
        let request = SKProductsRequest(productIdentifiers: products.allCases.map(\.rawValue))
        request.delegate = self

        dispatchGroup = DispatchGroup()

        dispatchGroup?.enter()
        request.start()
        self.request = request

        dispatchGroup?.notify(queue: .main, execute: {
            guard !self.products.isEmpty else {
                let message = "LOCAL:NoProductsFound.".localized
                let error = NSError(domain: "\(self.description)", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                completion(.failure(error))
                self.dispatchGroup = nil
                return
            }
            completion(.success(self.products))
            self.dispatchGroup = nil
        })
    }

    public func purchase<T: DSSIAPProduct>(product: T) {
        let skProducts = products.filter { $0.productIdentifier == product.rawValue }

        guard let skProduct = skProducts.first else { return }

        let payment = SKPayment(product: skProduct)
        paymentQueue.add(payment)
    }

    public func restorePurchases() {
        paymentQueue.restoreCompletedTransactions()
    }
}

extension DSSIAPService: SKProductsRequestDelegate {
    open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.products.forEach { product in
            if !products.contains(where: { $0.productIdentifier == product.productIdentifier }) { products.insert(product) }
        }
        dispatchGroup?.leave()
    }
}

extension DSSIAPService: SKPaymentTransactionObserver {
    open func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach {
//            print($0.transactionState.description)
//            queue.finishTransaction($0)
            #if DEBUG
            print("Product \($0.payment.productIdentifier): \($0.transactionState.description)")
            #endif
            if $0.transactionState == .failed { queue.finishTransaction($0) }
        }
    }
}
