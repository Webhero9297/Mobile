//
//  UIButton+BRWAdditions.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-24.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

extension UIButton {
    static func vertical(title: String, image: UIImage) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.titleLabel?.font = UIFont.customMedium(size: 12.0)
        button.contentMode = .center
        button.imageView?.contentMode = .center
        if let imageSize = button.imageView?.image?.size,
            let font = button.titleLabel?.font {
            let spacing: CGFloat = C.padding[1]/2.0
            let titleSize = NSString(string: title).size(withAttributes: [NSAttributedStringKey.font : font])

            // These edge insets place the image vertically above the title label
            button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(26.0 + spacing), 0.0)
            button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width)
        }
        return button
    }
    
    static func rounded(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.customMedium(size: 16.0)
        button.backgroundColor = .red
        button.layer.cornerRadius = 5
        return button
    }

    static func outline(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.customMedium(size: 16.0)
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.blue.cgColor
        return button
    }

    static var close: UIButton {
        let accessibilityLabel = E.isScreenshots ? "Close" : S.AccessibilityLabels.close
        return UIButton.icon(image: #imageLiteral(resourceName: "Close"), accessibilityLabel: accessibilityLabel)
    }

    static func buildFaqButton(articleId: String, currency: CurrencyDef? = nil) -> UIButton {
        let button = UIButton.icon(image: #imageLiteral(resourceName: "Faq"), accessibilityLabel: S.AccessibilityLabels.faq)
        button.tap = {
            Store.trigger(name: .presentFaq(articleId, currency))
        }
        return button
    }

    static func icon(image: UIImage, accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.setImage(image, for: .normal)

        if image == #imageLiteral(resourceName: "Close") {
            button.imageEdgeInsets = UIEdgeInsetsMake(14.0, 14.0, 14.0, 14.0)
        } else {
            button.imageEdgeInsets = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0)
        }

        button.tintColor = .darkText
        button.accessibilityLabel = accessibilityLabel
        return button
    }
    
    static func icon(image: UIImage, title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: C.padding[2], bottom: 0, right: 0)
        button.titleLabel?.font = UIFont.customBody(size: 14.0)
        return button
    }

    func tempDisable() {
        isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
            self?.isEnabled = true
        })
    }
}
