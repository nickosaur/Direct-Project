//
//  NSObjectExtension.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import Foundation

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
    
    func objectAssertionFailure(withMessage messagge: String) {
        assertionFailure(self.className + ": " + messagge)
    }
}
