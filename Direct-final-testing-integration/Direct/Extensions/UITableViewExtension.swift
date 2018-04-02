//
//  UITableViewExtension.swift
//  Direct
//
//  Created by Kesong Xie on 10/25/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

extension UITableView {
    func registerNibCell(forClassName name: String) {
        let nib = UINib(nibName: name, bundle: nil)
        self.register(nib, forCellReuseIdentifier: name)
    }
}
