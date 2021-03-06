//
//  CoinsViewController+UICollectionView.swift
//  CoinBucket
//
//  Created by Christopher Lee on 10/12/17.
//  Copyright © 2017 Christopher Lee. All rights reserved.
//

import UIKit

extension CoinsViewController: UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if filteredCoins.count == 0 {
            collectionView.backgroundView?.isHidden = false
        } else {
            collectionView.backgroundView?.isHidden = true
        }
        
        return filteredCoins.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == coins.count - 1 && !isFinishedPaging {
            let loadingCell = collectionView.dequeueReusableCell(withReuseIdentifier: coinLoadingCell, for: indexPath) as! LoadingCell
            fetchMoreCoins()
            
            return loadingCell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: coinCell, for: indexPath) as! CoinCell
        let coin = filteredCoins[indexPath.item]
        let coinViewModel = CoinViewModel(model: coin)
        cell.stateController = stateController
        cell.displayCoinInCell(using: coinViewModel)
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCoin = filteredCoins[indexPath.item]
        let coinViewModel = CoinViewModel(model: selectedCoin)
        
        let coinDataView = CoinDataViewController(collectionViewLayout: UICollectionViewFlowLayout())
        coinDataView.model = coinViewModel
        coinDataView.coin = selectedCoin
        coinDataView.stateController = stateController
        navigationController?.pushViewController(coinDataView, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
            if let cell = collectionView.cellForItem(at: indexPath) as? CoinCell {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
            if let cell = collectionView.cellForItem(at: indexPath) as? CoinCell {
                cell.transform = .identity
            }
        }, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width - 24, height: 70)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let searchText = searchController.searchBar.text ?? ""

        if searchText.isEmpty {
            searchController.isActive = false
        } else {
            searchController.searchBar.endEditing(true)
        }
    }
}
