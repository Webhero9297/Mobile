//
//  CoinCell.swift
//  CoinBucket
//
//  Created by Christopher Lee on 10/12/17.
//  Copyright © 2017 Christopher Lee. All rights reserved.
//

import UIKit

class CoinCell: UICollectionViewCell {
    
    let coinImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 30/2
        iv.clipsToBounds = true
        return iv
    }()
    
    let coinLeftLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()
    
    let coinRightLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return view
    }()
    
    var stateController: StateController!
        
    override init(frame: CGRect) {
        super.init(frame: frame)

        configureUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureUI() {
        backgroundColor = .white
        
        // Sets cornerRadius and shadow
        self.contentView.layer.cornerRadius = 12.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
        
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        self.layer.shadowRadius = 1.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 12.0
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath

        addSubview(coinImageView)
        coinImageView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 30, height: 30)
        coinImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(coinRightLabel)
        coinRightLabel.anchor(top: topAnchor, left: nil, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)
        
        addSubview(coinLeftLabel)
        coinLeftLabel.anchor(top: topAnchor, left: coinImageView.rightAnchor, bottom: bottomAnchor, right: coinRightLabel.leftAnchor, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    
    func displayCoinInCell(using viewModel: CoinViewModel) {
        var percentChangeColor: UIColor

        if viewModel.percentChange24h > 0 {
            percentChangeColor = .green
        } else {
            percentChangeColor = .red
        }
        
        // LeftHandLabel
        let leftAttributedText = NSMutableAttributedString(string: viewModel.name, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)])
        leftAttributedText.append(NSAttributedString(string: " (\(viewModel.symbol))", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)]))
        leftAttributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 4)]))
        
        if let type = viewModel.coinType, type == viewType.PortfolioCoin.rawValue  {
            leftAttributedText.append(NSAttributedString(string: "Qty: \(viewModel.quantity)", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
            leftAttributedText.append(NSAttributedString(string: " @ \(viewModel.price.formatCurrency(localeIdentifier: stateController.currency.locale))", attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        } else {
            leftAttributedText.append(NSAttributedString(string: "\(viewModel.priceBTC) BTC", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        }
        
        // RightHandLabel
        if let type = viewModel.coinType, type == viewType.PortfolioCoin.rawValue  {
            let quantity = NSDecimalNumber(string: viewModel.quantity)
            let price = NSDecimalNumber(string: viewModel.price.toDecimals())
            let totalPrice = ((quantity as Decimal) * (price as Decimal)) as NSDecimalNumber
            
            let rightAttributedText = NSMutableAttributedString(string: totalPrice.formatCurrency(localeIdentifier: stateController.currency.locale), attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)])
            
            coinRightLabel.attributedText = rightAttributedText
        } else {
            let rightAttributedText = NSMutableAttributedString(string: viewModel.price.formatCurrency(localeIdentifier: stateController.currency.locale), attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)])
            rightAttributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 4)]))
            rightAttributedText.append(NSAttributedString(string: "\(viewModel.percentChange24h)%", attributes: [NSAttributedStringKey.foregroundColor: percentChangeColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
            
            coinRightLabel.attributedText = rightAttributedText
        }
        
        coinLeftLabel.attributedText = leftAttributedText
        coinImageView.loadImageUsingCacheWithURLString(viewModel.imageUrl, placeHolder: #imageLiteral(resourceName: "coin_deposit")) { (bool) in }
    }
}
