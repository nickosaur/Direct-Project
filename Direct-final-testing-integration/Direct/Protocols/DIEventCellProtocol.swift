//
//  DIEventCellProtocol.swift
//  Direct
//
//  Created by Kesong Xie on 11/11/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

protocol DIEventCellProtocol {
    var event: DIEvent! {get set}
}

class DIEventCell: UITableViewCell, DIEventCellProtocol {
    var event: DIEvent!
}
