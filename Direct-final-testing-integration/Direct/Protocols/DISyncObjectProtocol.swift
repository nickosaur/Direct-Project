//
//  DISyncObjectProtocol.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

enum DISyncOption
{
    case add
    case delete
}

protocol DISyncObjectProtocol: class {
    // sync data to server
    associatedtype T
    
    /**
     * the conforming class should provide the logic how to sync itself to the server
     */
    func sync(option: DISyncOption, completionBlock: ((T) -> Void)?)
}
