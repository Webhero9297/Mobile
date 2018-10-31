//
//  MenuItem.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-04-01.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

struct MenuItem {
    let title: String
    let icon: UIImage?
    let accessoryText: (() -> String)?
    let callback: () -> Void
    let faqButton: UIButton? = nil
    
    init(title: String, icon: UIImage? = nil, accessoryText: (() -> String)? = nil, callback: @escaping () -> Void) {
        self.title = title
        self.icon = icon?.withRenderingMode(.alwaysTemplate)
        self.accessoryText = accessoryText
        self.callback = callback
    }
    
    init(title: String, icon: UIImage? = nil, subMenu: [MenuItem], rootNav: UINavigationController, faqButton: UIButton? = nil) {
        let subMenuVC = MenuViewController(items: subMenu, title: title, faqButton: faqButton)
        self.init(title: title, icon: icon, accessoryText: nil) {
            rootNav.pushViewController(subMenuVC, animated: true)
        }
    }
}
