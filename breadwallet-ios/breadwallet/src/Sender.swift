//
//  Sender.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-01-16.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation
import UIKit
import BRCore

// MARK: Types/Constants

enum SendResult {
    case success(String?, String?) // tx hash, raw tx data
    case creationError(String)
    case publishFailure(BRPeerManagerError)
    case insufficientGas(String) // for ERC20 token transfers
}

enum SenderValidationResult {
    case ok
    case failed
    case invalidAddress
    case ownAddress
    case insufficientFunds
    case noExchangeRate
    
    // BTC errors
    case noFees // fees not downlaoded
    case outputTooSmall(UInt64)
    
    // protocol request errors
    case invalidRequest(String)
    case paymentTooSmall(UInt64)
    case usedAddress
    case identityNotCertified(String)
    
    // token errors
    case insufficientGas // no eth for token transfer gas
}

typealias PinVerifier = (@escaping (String) -> Void) -> Void
typealias SendCompletion = (SendResult) -> Void

// MARK: - Protocol

protocol Sender: class {
    
    var canUseBiometrics: Bool { get }

    func updateFeeRates(_ fees: Fees, level: FeeLevel?)
    func fee(forAmount: UInt256) -> UInt256?
    
    func validate(paymentRequest: PaymentProtocolRequest, ignoreUsedAddress: Bool, ignoreIdentityNotCertified: Bool) -> SenderValidationResult
    
    func createTransaction(address: String, amount: UInt256, comment: String?) -> SenderValidationResult
    func createTransaction(forPaymentProtocol: PaymentProtocolRequest) -> SenderValidationResult
    
    func sendTransaction(allowBiometrics: Bool,
                         pinVerifier: @escaping PinVerifier,
                         abi: String?,
                         completion: @escaping SendCompletion)
    
    func reset()
}

extension Sender {
    var canUseBiometrics: Bool { return false }
}

protocol GasEstimator {
    func hasFeeForAddress(_ address: String, amount: Amount) -> Bool
    func estimateGas(toAddress: String, amount: Amount)
}
// MARK: - Base Class

class SenderBase<CurrencyType: CurrencyDef, WalletType: WalletManager> {
    
    fileprivate let currency: CurrencyType
    fileprivate let walletManager: WalletType
    fileprivate let kvStore: BRReplicatedKVStore
    fileprivate var comment: String?
    fileprivate var readyToSend: Bool = false
    
    // MARK: Init
    
    fileprivate init(currency: CurrencyType, walletManager: WalletType, kvStore: BRReplicatedKVStore) {
        self.currency = currency
        self.walletManager = walletManager
        self.kvStore = kvStore
    }
    
    // MARK: -
    
    func validate(paymentRequest req: PaymentProtocolRequest, ignoreUsedAddress: Bool, ignoreIdentityNotCertified: Bool) -> SenderValidationResult {
        return .failed
    }
    
    func createTransaction(forPaymentProtocol: PaymentProtocolRequest) -> SenderValidationResult {
        return .failed
    }
    
    func reset() {
        comment = nil
        readyToSend = false
    }
}

// MARK: -

class BitcoinSender: SenderBase<Bitcoin, BTCWalletManager>, Sender {
    
    // MARK: Sender
    
    var canUseBiometrics: Bool {
        guard let tx = transaction else { return false }
        return walletManager.canUseBiometrics(forTx: tx)
    }
    
    func updateFeeRates(_ fees: Fees, level: FeeLevel?) {
        walletManager.wallet?.feePerKb = fees.fee(forLevel: level ?? .regular)
    }
    
    func fee(forAmount amount: UInt256) -> UInt256? {
        guard let fee = walletManager.wallet?.feeForTx(amount: amount.asUInt64) else { return nil }
        return UInt256(fee)
    }
    
    func createTransaction(address: String, amount: UInt256, comment: String?) -> SenderValidationResult {
        let btcAddress = currency.matches(Currencies.bch) ? address.bitcoinAddr : address
        let result = validate(address: btcAddress, amount: amount)
        guard case .ok = result else { return result }
        
        transaction = walletManager.wallet?.createTransaction(forAmount: amount.asUInt64, toAddress: btcAddress)
        
        guard transaction != nil else {
            reset()
            return .failed
        }
        
        self.comment = comment
        readyToSend = true
        
        return result
    }
    
    override func validate(paymentRequest req: PaymentProtocolRequest, ignoreUsedAddress: Bool, ignoreIdentityNotCertified: Bool) -> SenderValidationResult {
        guard let firstOutput = req.details.outputs.first else { return .failed }
        guard let wallet = walletManager.wallet else { return .failed }
        
        let errorMessage = req.errorMessage ?? ""
        let address = firstOutput.swiftAddress
        
        guard req.isValid() else { return .invalidRequest(errorMessage)}
        
        if errorMessage == S.PaymentProtocol.Errors.requestExpired {
            return .invalidRequest(errorMessage)
        }
        
        //TODO: check for duplicates of already paid requests
        var isOutputTooSmall = false
        let requestAmount = UInt256(req.amount)
        req.details.outputs.forEach { output in
            if output.amount > 0 && output.amount < wallet.minOutputAmount {
                isOutputTooSmall = true
            }
        }
        
        guard !walletManager.isOwnAddress(address) else { return .ownAddress }
        guard ignoreUsedAddress || !wallet.addressIsUsed(address) else { return .usedAddress }
        guard ignoreIdentityNotCertified || errorMessage.utf8.isEmpty || req.commonName!.utf8.isEmpty else { return .identityNotCertified(errorMessage) }
        
        guard requestAmount >= wallet.minOutputAmount else {
            return .paymentTooSmall(wallet.minOutputAmount)
        }
        guard !isOutputTooSmall else {
            return .outputTooSmall(wallet.minOutputAmount)
        }
        
        return .ok
    }
    
    override func createTransaction(forPaymentProtocol req: PaymentProtocolRequest) -> SenderValidationResult {
        let result = validate(paymentRequest: req, ignoreUsedAddress: true, ignoreIdentityNotCertified: true)
        guard case .ok = result else { return result }
        let wallet = walletManager.wallet!
        
        protocolRequest = req
        let feePerKb = wallet.feePerKb
        
        let requiredFeeRate = UInt64(req.details.requiredFeeRate*1000)
        if requiredFeeRate >= feePerKb {
            wallet.feePerKb = requiredFeeRate
            transaction = wallet.createTxForOutputs(req.details.outputs)
            wallet.feePerKb = feePerKb
        } else {
            transaction = wallet.createTxForOutputs(req.details.outputs)
        }
        
        guard transaction != nil else {
            reset()
            return .failed
        }
        
        comment = req.details.memo
        
        
        return result
    }
    
    override func reset() {
        transaction = nil
        super.reset()
    }
    
    func sendTransaction(allowBiometrics: Bool, pinVerifier: @escaping PinVerifier, abi: String? = nil, completion: @escaping SendCompletion) {
        guard readyToSend, let tx = transaction else { return completion(.creationError("not ready")) }
        
        if allowBiometrics && UserDefaults.isBiometricsEnabled && walletManager.canUseBiometrics(forTx: tx) {
            sendWithBiometricVerification(tx: tx, pinVerifier: pinVerifier, completion: completion)
        } else {
            sendWithPinVerification(tx: tx, pinVerifier: pinVerifier, completion: completion)
        }
    }
    
    // MARK: Private
    
    private var transaction: BRTxRef?
    private var protocolRequest: PaymentProtocolRequest?
    
    private func validate(address: String, amount: UInt256) -> SenderValidationResult {
        guard address.isValidAddress else { return .invalidAddress }
        guard !walletManager.isOwnAddress(address) else { return .ownAddress }
        guard currency.state?.currentRate != nil else { return .noExchangeRate }
        
        if let minOutput = walletManager.wallet?.minOutputAmount {
            guard amount >= minOutput else { return .outputTooSmall(minOutput) }
        }
        
        guard amount <= (walletManager.wallet?.maxOutputAmount ?? 0) else {
            return .insufficientFunds
        }
        
        if currency.matches(Currencies.btc) {
            guard currency.state?.fees != nil else {
                return .noFees
            }
        }
        
        return .ok
    }
    
    private func sendWithBiometricVerification(tx: BRTxRef,
                                               pinVerifier: @escaping PinVerifier,
                                               completion: @escaping SendCompletion) {
        let biometricsPrompt = S.VerifyPin.touchIdMessage
        
        DispatchQueue.walletQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.walletManager.signTransaction(tx, forkId: self.currency.forkId, biometricsPrompt: biometricsPrompt, completion: { result in
                switch result {
                case .success:
                    self.publish(tx: tx, completion: completion)
                case .failure, .fallback:
                    self.sendWithPinVerification(tx: tx,
                                                 pinVerifier: pinVerifier,
                                                 completion: completion)
                default:
                    break
                }
            })
        }
    }
    
    private func sendWithPinVerification(tx: BRTxRef,
                                         pinVerifier: PinVerifier,
                                         completion: @escaping SendCompletion) {
        pinVerifier { pin in
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.walletQueue.async {
                if self.walletManager.signTransaction(tx, forkId: self.currency.forkId, pin: pin) {
                    self.publish(tx: tx, completion: completion)
                }
                group.leave()
            }
            let result = group.wait(timeout: .now() + 4.0)
            if result == .timedOut {
                fatalError("send-tx-timeout")
            }
        }
    }
    
    private func publish(tx: BRTxRef,
                         completion: @escaping SendCompletion) {
        DispatchQueue.walletQueue.async {
            if self.protocolRequest?.mimeType == "application/payment-request" {
                return self.postProtocolPaymentIfNeeded(completion: completion)
            }
            
            guard let peerManager = self.walletManager.peerManager else { return completion(.publishFailure(BRPeerManagerError.posixError(errorCode: -1, description: "network not connected")))}
            
            peerManager.publishTx(tx) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.publishFailure(error))
                    } else {
                        self.setMetaData(btcTx: tx)
                        let txData = Data(bytes: tx.bytes ?? [])
                        completion(.success(tx.pointee.txHash.description, txData.hexString))
                        self.postProtocolPaymentIfNeeded()
                    }
                }
            }
        }
    }
    
    private func setMetaData(btcTx: BRTxRef) {
        guard let rate = currency.state?.currentRate, let feePerKb = walletManager.wallet?.feePerKb else { print("Incomplete tx metadata"); return }
        guard let tx = BtcTransaction(btcTx, walletManager: walletManager, kvStore: kvStore, rate: rate) else { return }
        
        tx.createMetaData(rate: rate, comment: comment, feeRate: Double(feePerKb))
        Store.trigger(name: .txMemoUpdated(tx.hash))
    }
    
    private func postProtocolPaymentIfNeeded(completion: @escaping (SendResult) -> Void = { (nil) in }) {
        let protocolPaymentTimeout: TimeInterval = 20.0
        
        guard let protoReq = protocolRequest else { return }
        guard let wallet = walletManager.wallet else { return }
        let amount = protoReq.amount
        let payment = PaymentProtocolPayment(merchantData: protoReq.details.merchantData,
                                             transactions: [transaction],
                                             refundTo: [(address: wallet.receiveAddress, amount: amount)])
        payment?.currency = currency.code
        guard let urlString = protoReq.details.paymentURL else { return }
        guard let url = URL(string: urlString) else { return }
        
        let request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: protocolPaymentTimeout)
        request.httpMethod = "POST"
        
        if (protoReq.mimeType == "application/payment-request") {
            request.setValue("application/payment", forHTTPHeaderField: "Content-Type")
            request.addValue("application/payment-ack", forHTTPHeaderField: "Accept")
            request.httpBody = payment?.json?.data(using: .utf8)
        }
        else {
            request.setValue("application/bitcoin-payment", forHTTPHeaderField: "Content-Type")
            request.addValue("application/bitcoin-paymentack", forHTTPHeaderField: "Accept")
            request.httpBody = Data(bytes: payment!.bytes)
        }
        
        print("posting to: \(url)")
        
        URLSession.shared.dataTask(with: request as URLRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    print("payment error: \(error!)");
                    return completion(.publishFailure(.posixError(errorCode: 74, description: "\(error!)")))
                }
                
                guard let response = response, let data = data else {
                    print("no response or data");
                    return completion(.publishFailure(.posixError(errorCode: 74, description: "no response or data")))
                }
                
                if response.mimeType == "application/bitcoin-paymentack" && data.count <= 50000 {
                    if let ack = PaymentProtocolACK(data: data) {
                        print("received ack: \(ack)") //TODO - show memo to user
                        completion(.success(nil,nil))
                    }
                    else {
                        print("ack failed to deserialize")
                        completion(.publishFailure(.posixError(errorCode: 74, description: "ack failed to deserialize")))
                    }
                }
                else if response.mimeType == "application/payment-ack" && data.count <= 50000 {
                    if let ack = PaymentProtocolACK(json: String(data: data, encoding: .utf8) ?? "") {
                        print("received ack: \(ack)") //TODO - show memo to user
                        
                        if let tx = self?.transaction {
                            self?.setMetaData(btcTx: tx)
                            completion(.success(nil,nil))
                        }
                    }
                    else {
                        print("ack failed to deserialize")
                        completion(.publishFailure(.posixError(errorCode: 74, description: "ack failed to deserialize")))
                    }
                }
                else {
                    print("invalid data")
                    completion(.publishFailure(.posixError(errorCode: 74, description: "invalid data")))
                }
                
                print("finished!!")
            }
            }.resume()
    }
}

// MARK: -

/// Base class for sending Ethereum-network transactions
class EthSenderBase<CurrencyType: CurrencyDef> : SenderBase<CurrencyType, EthWalletManager>, GasEstimator {
    
    fileprivate var address: String?
    fileprivate var amount: UInt256?
    
    // MARK: Sender
    
    func updateFeeRates(_ fees: Fees, level: FeeLevel? = nil) {
        walletManager.gasPrice = fees.gasPrice
    }
    
    func createTransaction(address: String, amount: UInt256, comment: String?) -> SenderValidationResult {
        let result = validate(address: address, amount: amount)
        guard case .ok = result else { return result }
        
        self.amount = amount
        self.address = address
        self.comment = comment
        readyToSend = true
        
        return result
    }
    
    override func reset() {
        super.reset()
        amount = nil
        address = nil
    }
    
    // MARK: Private
    
    fileprivate func validate(address: String, amount: UInt256) -> SenderValidationResult {
        // must override
        return .failed
    }
    
    // MARK: GasEstimator
    
    fileprivate struct GasEstimate {
        let address: String
        let amount: Amount
        let estimate: UInt256
    }
    
    fileprivate var estimate: GasEstimate? = nil
    
    func hasFeeForAddress(_ address: String, amount: Amount) -> Bool {
        return estimate?.address == address && estimate?.amount.rawValue == amount.rawValue
    }
    
    func estimateGas(toAddress: String, amount: Amount) {
        estimate = nil
        guard let fromAddress = self.walletManager.address else { return }
        let params = transactionParams(fromAddress: fromAddress, toAddress: toAddress, forAmount: amount)
        Backend.apiClient.estimateGas(transaction: params, handler: { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let value):
                self.estimate = GasEstimate(address: toAddress, amount: amount, estimate: value)
            case .error(let error):
                print("estimate gas error: \(error)")
                self.estimate = nil
            }
        })
    }
    
    func transactionParams(fromAddress: String, toAddress: String, forAmount: Amount) -> TransactionParams {
        var params = TransactionParams(from: fromAddress, to: toAddress)
        params.value = forAmount.amount
        return params
    }
}

class EthereumSender: EthSenderBase<Ethereum>, Sender {
    
    // customGasPrice and customGasLimit parameters are only used for contract transactions
    // only used for che checkout feature
    var checkoutCustomGasPrice: UInt256?
    var checkoutCustomGasLimit: UInt256?
    
    private var gasPrice: UInt256 {
        return checkoutCustomGasPrice ?? walletManager.gasPrice
    }
    
    private var gasLimit: UInt256 {
        if let limit = checkoutCustomGasLimit {
            return limit
        } else if let limit = estimate?.estimate {
            return limit
        } else {
            return UInt256(walletManager.defaultGasLimit(currency: currency))
        }
    }
    
    // MARK: Sender
    
    func fee(forAmount: UInt256) -> UInt256? {
        return gasPrice * gasLimit
    }
    
    func sendTransaction(allowBiometrics: Bool, pinVerifier: @escaping PinVerifier, abi: String? = nil, completion: @escaping SendCompletion) {
        guard readyToSend,
            let address = address,
            let amount = amount else {
                return completion(.creationError("not ready"))
        }
        
        pinVerifier { pin in
            self.walletManager.sendTransaction(currency: self.currency, toAddress: address, amount: amount, abi: abi, gasPrice: self.gasPrice, gasLimit: self.gasLimit) { result in
                switch result {
                case .success(let pendingTx, nil, let rawTx):
                    self.setMetaData(tx: pendingTx)
                    completion(.success(pendingTx.hash, rawTx))
                case .error(let error):
                    switch error {
                    case .httpError(let e):
                        completion(.creationError(e?.localizedDescription ?? ""))
                    case .jsonError(let e):
                        completion(.creationError(e?.localizedDescription ?? ""))
                    case .rpcError(let e):
                        completion(.creationError(e.message))
                    }
                default:
                    assertionFailure("invalid parameters")
                }
            }
        }
    }
    
    // MARK: EthSenderBase
    
    fileprivate override func validate(address: String, amount: UInt256) -> SenderValidationResult {
        guard currency.isValidAddress(address) else { return .invalidAddress }
        guard !walletManager.isOwnAddress(address) else { return .ownAddress }
        if let balance = currency.state?.balance {
            guard amount < balance else { return .insufficientFunds }
        }
        //guard currency.state.currentRate != nil else { return .noExchangeRate } // allow sending without exchange rate
        return .ok
    }
    
    // MARK: Private
    
    private func setMetaData(tx: EthTransaction) {
        guard let rate = currency.state?.currentRate else { print("Incomplete tx metadata"); return }
        tx.createMetaData(rate: rate, comment: comment)
    }
}

// MARK: -

class ERC20Sender: EthSenderBase<ERC20Token>, Sender {
    
    // MARK: Sender
    private var gasLimit: UInt256 {
        if let limit = estimate?.estimate {
            return limit
        } else {
            return UInt256(walletManager.defaultGasLimit(currency: currency))
        }
    }
    
    func fee(forAmount: UInt256) -> UInt256? {
        return walletManager.gasPrice * UInt256(walletManager.defaultGasLimit(currency: currency))
    }
    
    func sendTransaction(allowBiometrics: Bool, pinVerifier: @escaping PinVerifier, abi: String? = nil, completion: @escaping SendCompletion) {
        guard readyToSend,
            let address = address,
            let amount = amount else {
                return completion(.creationError("not ready"))
        }

        pinVerifier { pin in
            self.walletManager.sendTransaction(currency: self.currency, toAddress: address, amount: amount, gasLimit: self.gasLimit) { result in
                switch result {
                case .success(let pendingEthTx, let pendingTokenTx?, let rawTx):
                    self.setMetaData(ethTx: pendingEthTx, tokenTx: pendingTokenTx)
                    completion(.success(pendingEthTx.hash, rawTx))
                case .error(let error):
                    switch error {
                    case .httpError(let e):
                        completion(.creationError(e?.localizedDescription ?? ""))
                    case .jsonError(let e):
                        completion(.creationError(e?.localizedDescription ?? ""))
                    case .rpcError(let e):
                        //TODO: hack, need a better way to detect this scenario
                        if e.message.hasPrefix("insufficient funds for gas") {
                            completion(.insufficientGas(e.message))
                        } else {
                            completion(.creationError(e.message))
                        }
                    }
                default:
                    assertionFailure("invalid parameters")
                }
            }
        }
    }
    
    // MARK: EthSenderBase
    
    fileprivate override func validate(address: String, amount: UInt256) -> SenderValidationResult {
        guard currency.isValidAddress(address) else { return .invalidAddress }
        guard !walletManager.isOwnAddress(address) else { return .ownAddress }
        if let balance = currency.state?.balance {
            guard amount <= balance else { return .insufficientFunds }
        }
        // ERC20 token transfers require ETH for gas
        if let ethBalance = Currencies.eth.state?.balance {
            guard ethBalance > UInt256(0) else { return .insufficientGas }
        }
        //guard currency.state.currentRate != nil else { return .noExchangeRate } // allow sending without exchange rate
        return .ok
    }
    
    // MARK: Private
    
    private func setMetaData(ethTx: EthTransaction, tokenTx: ERC20Transaction) {
        guard let ethRate = Currencies.eth.state?.currentRate,
            let tokenRate = currency.state?.currentRate else { print("Incomplete tx metadata"); return }
        
        // the ETH transaction (token transfer contract execution) is flagged as a token transfer with the token code
        ethTx.createMetaData(rate: ethRate, tokenTransfer: currency.code)
        tokenTx.createMetaData(rate: tokenRate, comment: comment)
    }
    
    // MARK: GasEstimator override
    
    override func transactionParams(fromAddress: String, toAddress: String, forAmount: Amount) -> TransactionParams {
        var params = TransactionParams(from: fromAddress, to: self.currency.address)
        let sig = "0xa9059cbb"
        let to = toAddress.withoutHexPrefix
        let amountString = forAmount.rawValue.hexString.withoutHexPrefix
        let addressPadding = Array(repeating: "0", count: 24).joined()
        let amountPadding = Array(repeating: "0", count: (66 - amountString.utf8.count)).joined()
        params.data = "\(sig)\(addressPadding)\(to)\(amountPadding)\(amountString)"
        return params
    }
    
}

// MARK: -

extension CurrencyDef {
    func createSender(walletManager: WalletManager, kvStore: BRReplicatedKVStore) -> Sender? {
        
        switch (self, walletManager) {
        case (is Bitcoin, is BTCWalletManager):
            return BitcoinSender(currency: self as! Bitcoin, walletManager: walletManager as! BTCWalletManager, kvStore: kvStore)
        case (is Ethereum, is EthWalletManager):
            return EthereumSender(currency: self as! Ethereum, walletManager: walletManager as! EthWalletManager, kvStore: kvStore)
        case (is ERC20Token, is EthWalletManager):
            return ERC20Sender(currency: self as! ERC20Token, walletManager: walletManager as! EthWalletManager, kvStore: kvStore)
        default:
            assertionFailure("unsupporeted currency/wallet")
            return nil
        }
    }
}
