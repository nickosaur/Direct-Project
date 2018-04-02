//
//  DIJsonTransformableProtocol.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import Foundation

protocol DIJsonTransformableProtocol: class {
    associatedtype T
    var info: [String: Any]? {get set}
    
    /** Convert idInfoPairs to an array to objects with T type
     *  idInfoPairs key is the id for the object, value is the info that needs to
     *  initialize the object
     */
    static func transformObjectArraysFrom(idInfoPairs: [String: [String: Any]]) -> [T]
}
