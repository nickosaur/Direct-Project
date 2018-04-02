//
//  UICollectionViewExtension.swift
//  Direct
//
//  Created by Kesong Xie on 10/30/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

extension UICollectionView {
    func registerNibCell(forClassName name: String) {
        let nib = UINib(nibName: name, bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: name)
    }
}
