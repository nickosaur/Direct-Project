//
//  StoryboardInstantiable.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

/** Any conformance should have a storyboard identifier set up at the stroyboard, and return the view controller correspondingly
 */
protocol StoryboardInstantiable: class {
    associatedtype T
    static func instantiateFromInstoryboard() -> T
}
