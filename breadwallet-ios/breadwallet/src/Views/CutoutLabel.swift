//
//  CutoutLabel.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2018-06-15.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit

class CutoutLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, .zero))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setBlendMode(.clear)
        UIColor.darkBackground.setFill()
        UIRectFill(rect)
        super.drawText(in: rect)
        context.restoreGState()
    }
}
