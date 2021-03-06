//
//  PortfolioViewController+Service.swift
//  CoinBucket
//
//  Created by Christopher Lee on 7/3/18.
//  Copyright © 2018 Christopher Lee. All rights reserved.
//

import UIKit

extension PortfolioViewController {
    // MARK: - Get Request Specific Coin
    func getCoin<S: Gettable>(fromService service: S) where S.T == Array<Coin?> {
        service.get { [weak self] (result) in
            self?.collectionView?.refreshControl?.endRefreshing()
            
            switch result {
            case .Success(let coins):
                let userDefaults = UserDefaults.standard
                var coin = coins[0]!
                
                if let data = userDefaults.value(forKey: "savedCoins") as? Data {
                    var coinDict = try? PropertyListDecoder().decode([String: Coin].self, from: data)

                    for (key, _) in coinDict! {
                        if (key == coin.symbol) {
                            coin.quantity = coinDict![key]?.quantity
                            coinDict![key] = coin
                        }
                    }
                    
                    userDefaults.set(try? PropertyListEncoder().encode(coinDict), forKey: "savedCoins")
                }
                
                let now = Date()
                let updateString = now.toString(dateFormat: "d MMM yyyy h:mm a")
                self?.collectionView?.refreshControl?.attributedTitle = NSAttributedString(string: "Last updated \(updateString)")

                self?.setupCoins()
                self?.collectionView?.reloadData()
                self?.loadingHUD.hide()
            case .Error(let error):
                // Shows alertController & loadingHUD
                if self?.savedCoins.count == 0 {
                    self?.loadingHUD.showFail(text: "Unable to get coin :(")
                    let alertController = UIAlertController(title: nil, message: "Oops! Failed to retrieve coins.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                    
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                        self?.loadingHUD.hide()
                    })
                }
                print(error)
            }
        }
    }
}
