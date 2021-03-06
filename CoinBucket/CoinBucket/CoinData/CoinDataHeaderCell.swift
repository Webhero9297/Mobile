//
//  CoinDataHeaderCell.swift
//  CoinBucket
//
//  Created by Christopher Lee on 13/3/18.
//  Copyright © 2018 Christopher Lee. All rights reserved.
//

import UIKit

class CoinDataHeaderCell: UICollectionViewCell {
    let topView: UIView = {
        let view = UIView()
        return view
    }()
    
    let priceView: UIView = {
        let view = UIView()
        return view
    }()
    
    let priceBTCView: UIView = {
        let view = UIView()
        return view
    }()
    
    let coinImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 30/2
        iv.clipsToBounds = true
        return iv
    }()
    
    let coinTitle: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let priceBTCLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let percentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let marketCapLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let volumeLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let supplyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let quantityLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let qtyTextField: TextField = {
        let tf = TextField()
        tf.placeholder = "Enter quantity"
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.textColor = .blue
        tf.keyboardType = UIKeyboardType.decimalPad
        tf.layer.cornerRadius = 6.0
        tf.layer.masksToBounds = true
        tf.backgroundColor = .groupTableViewBackground
        return tf
    }()
    
    let updateBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "coin_deposit"), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = .groupTableViewBackground
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.layer.cornerRadius = 12.0
        button.layer.masksToBounds = true
        return button
    }()
    
    let removeBtn: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.setImage(#imageLiteral(resourceName: "delete_trash").withRenderingMode(.alwaysOriginal), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = .groupTableViewBackground
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.layer.cornerRadius = 12.0
        button.layer.masksToBounds = true
        
        return button
    }()
    
    let coinDataContainer: UIView = {
        let coinDataContainer = UIView()
        coinDataContainer.backgroundColor = .white
        
        coinDataContainer.layer.cornerRadius = 12.0
        coinDataContainer.layer.borderWidth = 1.0
        coinDataContainer.layer.borderColor = UIColor.clear.cgColor
        coinDataContainer.layer.masksToBounds = true
        
        coinDataContainer.layer.shadowColor = UIColor.lightGray.cgColor
        coinDataContainer.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        coinDataContainer.layer.shadowRadius = 1.0
        coinDataContainer.layer.shadowOpacity = 0.5
        coinDataContainer.layer.masksToBounds = false
        coinDataContainer.layer.cornerRadius = 12.0
        
        return coinDataContainer
    }()
    
    let alertController: UIAlertController = {
        let alert = UIAlertController(title: "Bucket Updated", message: "Succesfully updated bucket!", preferredStyle: .alert)
        return alert
    }()
    
    let removeAlertController: UIAlertController = {
        let alert = UIAlertController(title: "Bucket Updated", message: "Succesfully removed coin from bucket!", preferredStyle: .alert)
        return alert
    }()
    
    weak var navigationController: UINavigationController?
    
    var model: CoinViewModel?
    var coin: Coin?
    var stateController: StateController? {
        didSet {
            setupCoin()
        }
    }
    
    let userDefaults = UserDefaults.standard
    
    let imageSize: CGFloat = 32
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        qtyTextField.delegate = self

        configureUI()
        setupCoin()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        coinImageView.frame = CGRect(x: 0, y: topView.frame.height / 2 - imageSize / 2, width: imageSize, height: imageSize)
        qtyTextField.frame.size.height = 30
        
        guard let coin = coin else { return }
        
        if coin.quantity == nil || coin.quantity == "0" {
            removeBtn.isHidden = true
        } else {
            removeBtn.isHidden = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func configureUI() {
        backgroundColor = .groupTableViewBackground

        addSubview(coinDataContainer)
        coinDataContainer.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 12, paddingLeft: 12, paddingBottom: 24, paddingRight: 12, width: 0, height: 0)

        coinDataContainer.addSubview(topView)
        topView.anchor(top: coinDataContainer.topAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 24, paddingRight: 24, width: coinDataContainer.frame.width, height: 40)

        topView.addSubview(coinImageView)
        coinImageView.anchor(top: topView.topAnchor, left: topView.leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: imageSize, height: imageSize)

        topView.addSubview(coinTitle)
        coinTitle.anchor(top: topView.topAnchor, left: coinImageView.rightAnchor, bottom: topView.bottomAnchor, right: topView.rightAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        coinDataContainer.addSubview(quantityLabel)
        quantityLabel.anchor(top: topView.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 0)
        
        coinDataContainer.addSubview(updateBtn)
        updateBtn.anchor(top: topView.bottomAnchor, left: nil, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 50, height: 0)
        updateBtn.addTarget(self, action: #selector(updateBucket), for: .touchUpInside)
        
        coinDataContainer.addSubview(removeBtn)
        removeBtn.anchor(top: topView.bottomAnchor, left: nil, bottom: nil, right: updateBtn.leftAnchor, paddingTop: 24, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 50, height: 0)
        removeBtn.addTarget(self, action: #selector(removeFromBucket), for: .touchUpInside)

        coinDataContainer.addSubview(qtyTextField)
        qtyTextField.anchor(top: quantityLabel.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: removeBtn.leftAnchor, paddingTop: 4, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 0)
        qtyTextField.frame.size.height = 100

        coinDataContainer.addSubview(priceView)
        priceView.anchor(top: qtyTextField.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 24, paddingRight: 24, width: 0, height: 0)

        priceView.addSubview(priceLabel)
        priceLabel.anchor(top: priceView.topAnchor, left: priceView.leftAnchor, bottom: priceView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        priceView.addSubview(percentLabel)
        percentLabel.anchor(top: priceView.topAnchor, left: nil, bottom: priceView.bottomAnchor, right: priceView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        coinDataContainer.addSubview(priceBTCView)
        priceBTCView.anchor(top: priceView.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 24, paddingRight: 24, width: 0, height: 0)

        priceBTCView.addSubview(priceBTCLabel)
        priceBTCLabel.anchor(top: priceBTCView.topAnchor, left: priceBTCView.leftAnchor, bottom: priceBTCView.bottomAnchor, right: priceBTCView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)

        coinDataContainer.addSubview(marketCapLabel)
        marketCapLabel.anchor(top: priceBTCView.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 0)

        coinDataContainer.addSubview(volumeLabel)
        volumeLabel.anchor(top: marketCapLabel.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 0)

        coinDataContainer.addSubview(supplyLabel)
        supplyLabel.anchor(top: volumeLabel.bottomAnchor, left: coinDataContainer.leftAnchor, bottom: nil, right: coinDataContainer.rightAnchor, paddingTop: 24, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, width: 0, height: 0)
    }
    
    fileprivate func setupCoin() {
        if let data = userDefaults.value(forKey: "savedCoins") as? Data {
            do {
                var coinDict = try PropertyListDecoder().decode([String: Coin].self, from: data)
                let symbol = coin?.symbol
                coin?.quantity = coinDict[symbol!]?.quantity
            } catch {
                print(error)
            }
        }
        
        var percentChangeColor: UIColor

        guard let currency = stateController?.currency else { return }
        guard let model = model else { return }
        guard let coin = coin else { return }

        coinImageView.loadImageUsingCacheWithURLString(model.imageUrl, placeHolder: #imageLiteral(resourceName: "coin_deposit")) { (bool) in }
        
        let attributedText = NSMutableAttributedString(string: model.name, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 30)])
        attributedText.append(NSAttributedString(string: " (\(model.symbol))", attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20), NSAttributedStringKey.foregroundColor: UIColor.gray]))
        coinTitle.attributedText = attributedText
        
        quantityLabel.attributedText = NSMutableAttributedString(string: "Bucket Qty", attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 24)])
        if coin.quantity != "0" {
            qtyTextField.text = coin.quantity
        }
        
        priceLabel.attributedText = setupAttributedText(firstString: "Price", secondString: "\(currency.name) \(model.price.formatCurrency(localeIdentifier: (stateController?.currency.locale)!))", color: .gray)
        
        priceBTCLabel.attributedText = setupAttributedText(firstString: "Price (BTC)", secondString: "\(model.priceBTC) BTC", color: .gray)
        
        if model.percentChange24h > 0 {
            percentChangeColor = .green
        } else {
            percentChangeColor = .red
        }
        percentLabel.attributedText = setupAttributedText(firstString: "(%)", secondString: "\(model.percentChange24h)%", color: percentChangeColor)
        
        marketCapLabel.attributedText = setupAttributedText(firstString: "Market Cap", secondString: "\(currency.name) \(model.marketCap.formatCurrency(localeIdentifier: (stateController?.currency.locale)!))", color: .gray)
        
        volumeLabel.attributedText = setupAttributedText(firstString: "Volume (24h)", secondString: "\(currency.name) \(model.volume.formatCurrency(localeIdentifier: (stateController?.currency.locale)!))", color: .gray)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: model.availableSupply)
        supplyLabel.attributedText = setupAttributedText(firstString: "Circulating Supply", secondString: "\(String(describing: formattedNumber!)) \(model.symbol)", color: .gray)
    }
    
    fileprivate func setupAttributedText(firstString: String, secondString: String, color: UIColor) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(string: firstString, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 24)])
        attributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 4)]))
        attributedText.append(NSAttributedString(string: secondString, attributes: [NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18)]))
        return attributedText
    }
    
    func deleteCoin() {
        guard let coin = coin else { return }
        let symbol = coin.symbol
        
        if let data = userDefaults.value(forKey: "savedCoins") as? Data {
            do {
                var currentCoinsDict = try PropertyListDecoder().decode([String: Coin].self, from: data)
                
                currentCoinsDict.removeValue(forKey: symbol)
                
                userDefaults.set(try PropertyListEncoder().encode(currentCoinsDict), forKey: "savedCoins")
                removeAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (error) -> Void in
                    self?.navigationController?.popViewController(animated: true)
                }))
                
                self.window?.rootViewController?.present(removeAlertController, animated: true, completion: nil)
            } catch {
                print(error)
                removeAlertController.title = "Failed"
                removeAlertController.message = "Failed to update bucket :(."
                self.window?.rootViewController?.present(removeAlertController, animated: true, completion: nil)
            }
        }
    }
    
    func dismissCell() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - #Selector Events
    // Remove saved coin from UserDefaults
    @objc func removeFromBucket() {
        let alertActionSheet = UIAlertController(title: "Are you sure you wish to remove this coin from your bucket? ", message: nil, preferredStyle: .actionSheet)
        alertActionSheet.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
            self.deleteCoin()
        }))
        alertActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertActionSheet.popoverPresentationController?.sourceView = removeBtn
        alertActionSheet.popoverPresentationController?.sourceRect = removeBtn.bounds
        alertActionSheet.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.right;

        self.window?.rootViewController?.present(alertActionSheet, animated: true, completion: nil)
    }
    
    // Update/Save coin to UserDefaults
    @objc func updateBucket() {
        endEditing(true)
        guard let coinQty = qtyTextField.text, !coinQty.isEmpty else { return }
        guard var coin = coin else { return }
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismissCell()
        }))
        
        let symbol = coin.symbol
        coin.quantity = coinQty
        
        let coinsDict: [String: Coin] = ["\(symbol)": coin]
        
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.value(forKey: "savedCoins") as? Data {
            do {
                var currentCoinsDict = try PropertyListDecoder().decode([String: Coin].self, from: data)
                
                currentCoinsDict[symbol] = coin
                
                userDefaults.set(try PropertyListEncoder().encode(currentCoinsDict), forKey: "savedCoins")

                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            } catch {
                print(error)
                alertController.title = "Failed"
                alertController.message = "Failed to update bucket :(."
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        } else {
            do {
                userDefaults.set(try PropertyListEncoder().encode(coinsDict), forKey: "savedCoins")
                
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            } catch {
                print(error)
                alertController.title = "Failed"
                alertController.message = "Failed to update bucket :(."
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

