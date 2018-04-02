//
//  UIFontWeightExtension.swift
//  Direct
//
//  Created by Kesong Xie on 10/19/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

extension UIFont.Weight {
    var name: String{
        switch self{
        case .bold:
            return "Bold"
        case .regular:
            return "Regular"
        case .medium:
            return "Medium"
        case .heavy:
            return "Heavy"
        default:
            return "Regular"
        }
    }
}
