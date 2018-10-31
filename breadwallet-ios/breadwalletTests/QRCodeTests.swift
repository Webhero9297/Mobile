//
//  QRCodeTests.swift
//  breadwalletTests
//
//  Created by Ehsan Rezaie on 2018-07-03.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import XCTest
@testable import breadwallet

class QRCodeTests: XCTestCase {
    
    func testPaymentRequests() {
        // invalid
        assertInvalidQRCode(fromContent: "")
        assertInvalidQRCode(fromContent: "0000000000000000000000000000000000")
        assertInvalidQRCode(fromContent: "bitcoin:qp0k6fs6q2hzmpyps3vtwmpx80j9w0r0acmp8l6e9v") // bch
        assertInvalidQRCode(fromContent: "bitcoin:0xC2D7CF95645D33006175B78989035C7c9061d3F9") // eth
        assertInvalidQRCode(fromContent: "bitcoincash:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq") // bech32
        assertInvalidQRCode(fromContent: "ethereum:1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2") // btc
        assertInvalidQRCode(fromContent: "ethereum:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq") // bech32
        assertInvalidQRCode(fromContent: "ethereum:qp0k6fs6q2hzmpyps3vtwmpx80j9w0r0acmp8l6e9v") // bch
        
        // BTC
        assertPaymentRequest(fromContent: "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", currency: Currencies.btc) // P2PKH
        assertPaymentRequest(fromContent: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", currency: Currencies.btc) // SegWit
        assertPaymentRequest(fromContent: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq", currency: Currencies.btc) // bech32
        assertPaymentRequest(fromContent: "bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=1.2&message=Payment&label=Satoshi", currency: Currencies.btc)
        
        assertPaymentRequest(fromContent: "bitcoin:1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2", currency: Currencies.btc) // P2PKH
        assertPaymentRequest(fromContent: "bitcoin:3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy", currency: Currencies.btc) // SegWit
        assertPaymentRequest(fromContent: "bitcoin:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq", currency: Currencies.btc) // bech32

        // BCH
        assertPaymentRequest(fromContent: "bitcoincash:qp0k6fs6q2hzmpyps3vtwmpx80j9w0r0acmp8l6e9v", currency: Currencies.bch)
        assertPaymentRequest(fromContent: "qp0k6fs6q2hzmpyps3vtwmpx80j9w0r0acmp8l6e9v", currency: Currencies.bch)
        
        // ETH
        assertPaymentRequest(fromContent: "0xC2D7CF95645D33006175B78989035C7c9061d3F9", currency: Currencies.eth)
        assertPaymentRequest(fromContent: "ethereum:0xC2D7CF95645D33006175B78989035C7c9061d3F9", currency: Currencies.eth)
        assertPaymentRequest(fromContent: "ether:0xC2D7CF95645D33006175B78989035C7c9061d3F9", currency: Currencies.eth)
        
        // Payment Protocol
        assertPaymentRequest(fromContent: "https://www.syndicoin.co/signednoroot.paymentrequest", currency: Currencies.btc)
    }
    
    func testPrivateKeys() {
        let wif = "5JqvntwHyQrAKDpgF9as6Dm9NaG1HBHwAhkabw6LHwzSpCriYWG"
        let bip38 = "6PRSLTTE9u953i5Tx3vQEMtwy4d8VBrZ7BwPn6tWhWadgviU3w9XvHR6er"
        guard case QRCode.privateKey(let wifKey) = QRCode(content: wif), wifKey == wif else { return XCTFail() }
        guard case QRCode.privateKey(let bip38Key) = QRCode(content: bip38), bip38Key == bip38 else { return XCTFail() }
    }
    
    func testPairingRequests() {
        let req = "https://brd.com/x/link-wallet?pubKey=5JqvntwHyQrAKDpgF9as6Dm9NaG1HBHwAhkabw6LHwzSpCriYWG&svc=SERVICE_ID&redirectURI=https://brd.com/redirect"
        guard case QRCode.deepLink(_) = QRCode(content: req) else { return XCTFail() }
    }
    
    // MARK: - Helpers
    
    private func assertPaymentRequest(fromContent content: String, currency: CurrencyDef, file: StaticString = #file, line: UInt = #line) {
        if case QRCode.paymentRequest(let request) = QRCode(content: content) {
            XCTAssertEqual(request.currency.code, currency.code, file: file, line: line)
        } else {
            XCTFail("invalid payment request URI", file: file, line: line)
        }
    }
    
    private func assertInvalidQRCode(fromContent content: String, file: StaticString = #file, line: UInt = #line) {
        let result = QRCode(content: content)
        guard case .invalid = result else {
            return XCTFail(file: file, line: line)
        }
    }
}
