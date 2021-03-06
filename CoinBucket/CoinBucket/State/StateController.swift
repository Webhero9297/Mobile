//
//  StateController.swift
//  CoinBucket
//
//  Created by Christopher Lee on 23/12/17.
//  Copyright © 2017 Christopher Lee. All rights reserved.
//

var userDefaults = UserDefaults.standard

import Foundation

class StateController {
    var currency: Currency
    
    init(currency: Currency) {
        self.currency = currency
    }
}
