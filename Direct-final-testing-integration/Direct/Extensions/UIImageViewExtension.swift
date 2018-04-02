//
//  UIImageViewExtension.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit
import AFNetworking

extension UIImageView {
    func loadImage(fromURL url: URL) {
        self.setImageWith(url)
    }
    
    func loadImage(fromData data: Data) {
        DispatchQueue.main.async {
            self.image = UIImage(data: data)
        }
    }
    
    func setCornerRadius(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}
