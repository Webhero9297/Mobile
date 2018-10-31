//
//  AmountViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

private let currencyHeight: CGFloat = 80.0
private let feeHeight: CGFloat = 130.0

class AmountViewController : UIViewController, Trackable {
    
    private let currency: CurrencyDef

    init(currency: CurrencyDef, isPinPadExpandedAtLaunch: Bool, isRequesting: Bool = false) {
        self.currency = currency
        self.isPinPadExpandedAtLaunch = isPinPadExpandedAtLaunch
        self.isRequesting = isRequesting
        if let rate = currency.state?.currentRate, Store.state.isBtcSwapped {
            self.currencyToggle = BRDButton(title: "\(rate.code) (\(rate.currencySymbol))", type: .tertiary)
        } else {
            let title = currency.unitName(forDecimals: currency.state?.maxDigits ?? currency.commonUnit.decimals)
            self.currencyToggle = BRDButton(title: title, type: .tertiary)
        }
        self.feeSelector = FeeSelector()
        self.pinPad = PinPadViewController(style: .white, keyboardType: .decimalPad, maxDigits: currency.state?.maxDigits ?? currency.commonUnit.decimals, shouldShowBiometrics: false)
        self.canEditFee = (currency is Bitcoin)
        super.init(nibName: nil, bundle: nil)
    }

    var balanceTextForAmount: ((Amount?, Rate?) -> (NSAttributedString?, NSAttributedString?)?)?
    var didUpdateAmount: ((Amount?) -> Void)?
    var didChangeFirstResponder: ((Bool) -> Void)?

    var currentOutput: String {
        return amountLabel.text ?? ""
    }
    var selectedRate: Rate? {
        didSet {
            fullRefresh()
        }
    }
    var didUpdateFee: ((FeeLevel) -> Void)? {
        didSet {
            feeSelector.didUpdateFee = didUpdateFee
        }
    }
    
    var canEditFee: Bool
    
    func forceUpdateAmount(amount: Amount) {
        self.amount = amount
        fullRefresh()
    }

    func expandPinPad() {
        if pinPadHeight?.constant == 0.0 {
            togglePinPad()
        }
    }

    private let isPinPadExpandedAtLaunch: Bool
    private let isRequesting: Bool
    var minimumFractionDigits = 0
    private var hasTrailingDecimal = false
    private var pinPadHeight: NSLayoutConstraint?
    private var feeSelectorHeight: NSLayoutConstraint?
    private var feeSelectorTop: NSLayoutConstraint?
    private let placeholder = UILabel(font: .customBody(size: 16.0), color: .grayTextTint)
    private let amountLabel = UILabel(font: .customBody(size: 26.0), color: .darkText)
    private let pinPad: PinPadViewController
    private let currencyToggle: BRDButton
    private let border = UIView(color: .secondaryShadow)
    private let bottomBorder = UIView(color: .secondaryShadow)
    private let cursor = BlinkingView(blinkColor: C.defaultTintColor)
    private let balanceLabel = UILabel()
    private let feeLabel = UILabel()
    private let feeContainer = InViewAlert(type: .secondary)
    private let tapView = UIView()
    private let editFee = UIButton(type: .system)
    private let feeSelector: FeeSelector

    private var amount: Amount? {
        didSet {
            updateAmountLabel()
            updateBalanceLabel()
            didUpdateAmount?(amount)
        }
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        view.addSubview(amountLabel)
        view.addSubview(placeholder)
        view.addSubview(currencyToggle)
        view.addSubview(feeContainer)
        view.addSubview(border)
        view.addSubview(cursor)
        view.addSubview(balanceLabel)
        view.addSubview(feeLabel)
        view.addSubview(tapView)
        view.addSubview(bottomBorder)
        view.addSubview(editFee)
    }

    private func addConstraints() {
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            amountLabel.centerYAnchor.constraint(equalTo: currencyToggle.centerYAnchor) ])
        placeholder.constrain([
            placeholder.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: 2.0),
            placeholder.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor) ])
        cursor.constrain([
            cursor.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 2.0),
            cursor.heightAnchor.constraint(equalToConstant: 24.0),
            cursor.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            cursor.widthAnchor.constraint(equalToConstant: 2.0) ])
        currencyToggle.constrain([
            currencyToggle.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[2]),
            currencyToggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
        feeSelectorHeight = feeContainer.heightAnchor.constraint(equalToConstant: 0.0)
        feeSelectorTop = feeContainer.topAnchor.constraint(equalTo: feeLabel.bottomAnchor, constant: 0.0)

        feeContainer.constrain([
            feeSelectorTop,
            feeSelectorHeight,
            feeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        feeContainer.arrowXLocation = C.padding[4]

        let borderTop = isRequesting ? border.topAnchor.constraint(equalTo: currencyToggle.bottomAnchor, constant: C.padding[2]) : border.topAnchor.constraint(equalTo: feeContainer.bottomAnchor)
        border.constrain([
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderTop,
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
        balanceLabel.constrain([
            balanceLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            balanceLabel.topAnchor.constraint(equalTo: cursor.bottomAnchor) ])
        feeLabel.constrain([
            feeLabel.leadingAnchor.constraint(equalTo: balanceLabel.leadingAnchor),
            feeLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor),
            feeLabel.trailingAnchor.constraint(equalTo: editFee.leadingAnchor, constant: C.padding[1]) ])
        pinPadHeight = pinPad.view.heightAnchor.constraint(equalToConstant: 0.0)
        addChildViewController(pinPad, layout: {
            pinPad.view.constrain([
                pinPad.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pinPad.view.topAnchor.constraint(equalTo: border.bottomAnchor),
                pinPad.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pinPad.view.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor),
                pinPadHeight ])
        })
        editFee.constrain([
            editFee.centerYAnchor.constraint(equalTo: feeLabel.centerYAnchor, constant: -1.0),
            editFee.widthAnchor.constraint(equalToConstant: 44.0),
            editFee.heightAnchor.constraint(equalToConstant: 44.0) ])
        bottomBorder.constrain([
            bottomBorder.topAnchor.constraint(greaterThanOrEqualTo: currencyToggle.bottomAnchor, constant: C.padding[2]),
            bottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1.0) ])

        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapView.topAnchor.constraint(equalTo: view.topAnchor),
            tapView.trailingAnchor.constraint(equalTo: currencyToggle.leadingAnchor, constant: 4.0),
            tapView.bottomAnchor.constraint(equalTo: feeContainer.topAnchor) ])
        preventAmountOverflow()
    }

    private func setInitialData() {
        cursor.isHidden = true
        cursor.startBlinking()
        amountLabel.text = ""
        placeholder.text = S.Send.amountLabel
        bottomBorder.isHidden = true
        if Store.state.isBtcSwapped {
            if let rate = currency.state?.currentRate {
                selectedRate = rate
            }
        }
        pinPad.ouputDidUpdate = { [weak self] output in
            self?.handlePinPadUpdate(output: output)
        }
        currencyToggle.tap = strongify(self) { myself in
            myself.toggleCurrency()
        }
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapView.addGestureRecognizer(gr)
        tapView.isUserInteractionEnabled = true

        if isPinPadExpandedAtLaunch {
            didTap()
        }

        feeContainer.contentView = feeSelector
        editFee.tap = { [weak self] in
            self?.toggleFeeSelector()
        }
        editFee.setImage(#imageLiteral(resourceName: "Edit"), for: .normal)
        editFee.imageEdgeInsets = UIEdgeInsetsMake(15.0, 15.0, 15.0, 15.0)
        editFee.tintColor = .grayTextTint
        editFee.isHidden = true
        feeLabel.numberOfLines = 0
        feeLabel.lineBreakMode = .byWordWrapping
    }

    private func toggleCurrency() {
        saveEvent("amount.swapCurrency")
        selectedRate = selectedRate == nil ? currency.state?.currentRate : nil
        updateCurrencyToggleTitle()
    }

    private func preventAmountOverflow() {
        amountLabel.constrain([
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: currencyToggle.leadingAnchor, constant: -C.padding[2]) ])
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
    }

    private func handlePinPadUpdate(output: String) {
        let currencyDecimalSeparator = NumberFormatter().currencyDecimalSeparator ?? "."
        placeholder.isHidden = output.utf8.count > 0 ? true : false
        minimumFractionDigits = 0 //set default
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            let locationValue = output.distance(from: output.endIndex, to: decimalLocation)
            minimumFractionDigits = abs(locationValue)
        }

        //If trailing decimal, append the decimal to the output
        hasTrailingDecimal = false //set default
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            if output.endIndex == decimalLocation {
                hasTrailingDecimal = true
            }
        }

        if let rate = selectedRate {
            amount = Amount(fiatString: output,
                            currency: currency,
                            rate: rate)
        } else if let unit = currency.unit(forDecimals: currency.state?.maxDigits ?? currency.commonUnit.decimals) {
            amount = Amount(tokenString: output,
                            currency: currency,
                            unit: unit,
                            rate: selectedRate)
        } else {
            amount = nil
        }
    }

    private func updateAmountLabel() {
        guard let amount = amount else { amountLabel.text = ""; return }
        let displayAmount = Amount(amount: amount.rawValue,
                                   currency: currency,
                                   rate: selectedRate,
                                   minimumFractionDigits: minimumFractionDigits)
        var output = (selectedRate == nil) ? displayAmount.tokenFormattedValue : displayAmount.fiatDescription
        if hasTrailingDecimal {
            output = output.appending(NumberFormatter().currencyDecimalSeparator)
        }
        amountLabel.text = output
        placeholder.isHidden = output.utf8.count > 0 ? true : false
    }

    func updateBalanceLabel() {
        if let (balance, fee) = balanceTextForAmount?(amount, selectedRate) {
            balanceLabel.attributedText = balance
            feeLabel.attributedText = fee
            if let amount = amount, amount.rawValue > UInt256(0), !isRequesting {
                editFee.isHidden = !canEditFee
            } else {
                editFee.isHidden = true
            }
            balanceLabel.isHidden = cursor.isHidden
        }
    }

    private func toggleFeeSelector() {
        guard let height = feeSelectorHeight else { return }
        let isCollapsed: Bool = height.isActive
        UIView.spring(C.animationDuration, animations: {
            if isCollapsed {
                NSLayoutConstraint.deactivate([height])
                self.feeSelector.addIntrinsicSize()
            } else {
                self.feeSelector.removeIntrinsicSize()
                NSLayoutConstraint.activate([height])
            }
            self.parent?.parent?.view?.layoutIfNeeded()
        }, completion: {_ in })
    }

    @objc private func didTap() {
        UIView.spring(C.animationDuration, animations: {
            self.togglePinPad()
            self.parent?.parent?.view.layoutIfNeeded()
        }, completion: { completed in })
    }

    func closePinPad() {
        pinPadHeight?.constant = 0.0
        cursor.isHidden = true
        bottomBorder.isHidden = true
        updateBalanceAndFeeLabels()
        updateBalanceLabel()
    }

    private func togglePinPad() {
        let isCollapsed: Bool = pinPadHeight?.constant == 0.0
        pinPadHeight?.constant = isCollapsed ? pinPad.height : 0.0
        cursor.isHidden = isCollapsed ? false : true
        bottomBorder.isHidden = isCollapsed ? false : true
        updateBalanceAndFeeLabels()
        updateBalanceLabel()
        didChangeFirstResponder?(isCollapsed)
    }

    private func updateBalanceAndFeeLabels() {
        if let amount = amount, amount.rawValue > UInt256(0) {
            balanceLabel.isHidden = false
            if !isRequesting {
                editFee.isHidden = !canEditFee
            }
        } else {
            balanceLabel.isHidden = cursor.isHidden
            if !isRequesting {
                editFee.isHidden = true
            }
        }
    }

    private func fullRefresh() {
        updateCurrencyToggleTitle()
        updateBalanceLabel()
        updateAmountLabel()

        //Update pinpad content to match currency change
        //This must be done AFTER the amount label has updated
        let currentOutput = amountLabel.text ?? ""
        var set = CharacterSet.decimalDigits
        set.formUnion(CharacterSet(charactersIn: NumberFormatter().currencyDecimalSeparator))
        pinPad.currentOutput = String(String.UnicodeScalarView(currentOutput.unicodeScalars.filter { set.contains($0) }))
    }

    private func updateCurrencyToggleTitle() {
        guard let currencyState = currency.state else { return }
        if let rate = selectedRate {
            self.currencyToggle.title = "\(rate.code) (\(rate.currencySymbol))"
        } else {
            currencyToggle.title = currency.unitName(forDecimals: currencyState.maxDigits)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Fees : Equatable {}

func ==(lhs: Fees, rhs: Fees) -> Bool {
    return lhs.regular == rhs.regular && lhs.economy == rhs.economy
}
