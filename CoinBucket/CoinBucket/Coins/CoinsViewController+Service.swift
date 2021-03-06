
//
//  CoinsViewController+Service.swift
//  CoinBucket
//
//  Created by Christopher Lee on 17/12/17.
//  Copyright © 2017 Christopher Lee. All rights reserved.
//

import UIKit

extension CoinsViewController {
    // MARK: - Get Request Coins
    func getCoins<S: Gettable>(fromService service: S) where S.T == Array<Coin?> {
        service.get { [weak self] (result) in
            self?.collectionView?.refreshControl?.endRefreshing()
            
            switch result {
            case .Success(let coins):
                var tempCoins = [Coin]()
                for coin in coins {
                    if let coin = coin {
                        tempCoins.append(coin)
                    }
                }
                
                let now = Date()
                let updateString = now.toString(dateFormat: "d MMM yyyy h:mm a")
                self?.collectionView?.refreshControl?.attributedTitle = NSAttributedString(string: "Last updated \(updateString)")
                self?.coins = tempCoins
                self?.filteredCoins = tempCoins
                self?.loadingHUD.hide()
            case .Error(let error):
                // Shows alertController & loadingHUD
                print(error)
                self?.loadingHUD.showFail(text: "Network error :(")
                let alertController = UIAlertController(title: nil, message: "Oops! Sorry it seems there is currently an issue with our servers.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                    self?.loadingHUD.hide()
                })
            }
        }
    }
    
    // MARK: - Get Request More Coins
    func getMoreCoins<S: Gettable>(fromService service: S) where S.T == Array<Coin?> {
        service.get { [weak self] (result) in
            self?.collectionView?.refreshControl?.endRefreshing()
            
            switch result {
            case .Success(let coins):
                for coin in coins {
                    if let coin = coin {
                        self?.coins.append(coin)
                        self?.filteredCoins.append(coin)
                    }
                }
                if coins.count < 100 {
                    self?.isFinishedPaging = true
                }
            case .Error(let error):
                // Shows alertController & loadingHUD
                print(error)
                self?.loadingHUD.showFail(text: "Network error :(")
                let alertController = UIAlertController(title: nil, message: "Oops! Sorry it seems there is currently an issue with our servers.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
                
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                    self?.loadingHUD.hide()
                })
            }
        }
    }
    
    // MARK: - Get Request Specific Coin
    func getCoin<S: Gettable>(fromService service: S) where S.T == Array<Coin?> {
        service.get { [weak self] (result) in
            self?.collectionView?.refreshControl?.endRefreshing()
            
            switch result {
            case .Success(let coins):
                var tempCoins = [Coin]()
                for coin in coins {
                    if let coin = coin {
                        tempCoins.append(coin)
                    }
                }
                
                self?.filteredCoins = tempCoins
                self?.collectionView?.reloadData()
                self?.loadingHUD.hide()
            case .Error(let error):
                // Shows alertController & loadingHUD
                print(error)
                let alertController = UIAlertController(title: nil, message: "Oops! Sorry, we can't seem to find that coin.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    self?.loadingHUD.showFail(text: "Unable to find coin :(")

                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                        self?.loadingHUD.hide()
                    })
                }))
                self?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
