//
//  UIButtonExtension.swift
//  Direct
//
//  Created by Kesong Xie on 11/10/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

extension UIButton {
    func becomeRoundedButton() {
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.clipsToBounds = true
    }
}
