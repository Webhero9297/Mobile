//
//  NSMutableAttributedString+Additions.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-23.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation

extension NSMutableAttributedString {
    func set(attributes attrs: [NSAttributedStringKey: Any], forText text: String) {
        if let range = self.string.range(of: text) {
            setAttributes(attrs, range: NSRange(range, in: self.string))
        }
    }
}
