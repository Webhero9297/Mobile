//
//  PigeonRequest.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2018-07-27.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation
import BRCore

enum PigeonRequestType {
    case payment
    case call
}

protocol PigeonRequest {
    var currency: CurrencyDef { get }
    var address: String { get }
    var purchaseAmount: Amount { get }
    var memo: String { get }
    var type: PigeonRequestType { get }
    var abiData: String? { get }
    var txSize: UInt256? { get } // gas limit
    var txFee: Amount? { get } // gas price
}

private struct AssociatedKeys {
    static var responseCallback = "responseCallback"
}

private class CallbackWrapper : NSObject, NSCopying {

    init(_ callback: @escaping (CheckoutResult) -> Void) {
        self.callback = callback
    }

    let callback: (CheckoutResult) -> Void

    func copy(with zone: NSZone? = nil) -> Any {
        return CallbackWrapper(callback)
    }
}


extension PigeonRequest {

    var responseCallback: ((CheckoutResult) -> Void)? {
        get {
            guard let callbackWrapper = objc_getAssociatedObject(self, &AssociatedKeys.responseCallback) as? CallbackWrapper else { return nil }
            return callbackWrapper.callback
        }
        set {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.responseCallback, CallbackWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func getToken(completion: @escaping (ERC20Token?) -> Void) {
        Backend.apiClient.getToken(withSaleAddress: address) { result in
            guard case .success(let data) = result, let token = data.first else {
                print("[EME] error fetching token by sale address")
                completion(nil)
                return
            }
            completion(token)
        }
    }
}

class MessagePaymentRequestWrapper: PigeonRequest {
    private let paymentRequest: MessagePaymentRequest

    init(paymentRequest: MessagePaymentRequest) {
        self.paymentRequest = paymentRequest
    }

    var currency: CurrencyDef {
        return Currencies.eth
    }

    var purchaseAmount: Amount {
        return Amount(amount: UInt256(string: paymentRequest.amount), currency: currency)
    }

    var type: PigeonRequestType {
        return .payment
    }

    var abiData: String? {
        return nil
    }
    
    var address: String {
        return paymentRequest.address
    }
    
    var memo: String {
        return paymentRequest.memo
    }
    
    var txSize: UInt256? {
        return paymentRequest.hasTransactionSize ? UInt256(string: paymentRequest.transactionSize) : UInt256(100000)
    }
    
    var txFee: Amount? {
        return paymentRequest.hasTransactionFee ? Amount(amount: UInt256(string: paymentRequest.transactionFee), currency: currency) : nil
    }
}

class MessageCallRequestWrapper: PigeonRequest {

    private let callRequest: MessageCallRequest

    init(callRequest: MessageCallRequest) {
        self.callRequest = callRequest
    }

    var currency: CurrencyDef {
        return Currencies.eth
    }

    var purchaseAmount: Amount {
        return Amount(amount: UInt256(string: callRequest.amount), currency: currency)
    }

    var type: PigeonRequestType {
        return .call
    }

    var abiData: String? {
        return callRequest.abi
    }
    
    var address: String {
        return callRequest.address
    }
    
    var memo: String {
        return callRequest.memo
    }
    
    var txSize: UInt256? {
        return callRequest.hasTransactionSize ? UInt256(string: callRequest.transactionSize) : UInt256(200000)
    }
    
    var txFee: Amount? {
        return callRequest.hasTransactionFee ? Amount(amount: UInt256(string: callRequest.transactionFee), currency: currency) : nil
    }
}
