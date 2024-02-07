//
//  DSSPurchaseOperation.swift
//  DSSCukara
//
//  Created by David on 13/04/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import StoreKit

public protocol DSSPurchaseable {
    var description: String { get }
    var iapProduct: SKProduct? { get }
}

open class DSSPurchaseOperation: DSSAsyncOperation {
    public enum Status {
        case pending
        case purchasing
        case finished
        case failed
    }
    
    public var paymentQueue: SKPaymentQueue { .default() }
    public let purchaseable: DSSPurchaseable
    public private(set) var purchaseStatus: Status = .pending
    
    public init(purchaseable: DSSPurchaseable) {
        self.purchaseable = purchaseable
        super.init()
        paymentQueue.add(self)
    }
    
    override open func main() {
        guard let product = purchaseable.iapProduct else { return }
        let payment = SKPayment(product: product)
        paymentQueue.add(payment)
    }
}

extension DSSPurchaseOperation: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach {
            if $0.payment.productIdentifier == purchaseable.iapProduct?.productIdentifier {
                switch $0.transactionState {
                case .purchasing:
                    purchaseStatus = .purchasing
                case .purchased, .restored, .deferred:
                    queue.finishTransaction($0)
                    purchaseStatus = .finished
                    paymentQueue.remove(self)
                    state = .finished
                case .failed:
                    queue.finishTransaction($0)
                    purchaseStatus = .failed
                    paymentQueue.remove(self)
                    state = .finished
                @unknown default:
                    fatalError("Apple added a new case to SKPaymentTransactionState")
                }
            }
        }
    }
}
