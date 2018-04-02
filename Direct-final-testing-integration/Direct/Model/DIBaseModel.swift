//
//  DIBaseModel.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIBaseModel.swift
 *
 * This file is used to handle the connection with the database, for which this
 * application uses firebase.
 */

import FirebaseDatabase

class DIBaseModel: NSObject{
    var id: String!
    
    // get the reference to the database
    static var DatabaseReference: DatabaseReference = Database.database().reference()
    
    /* ==
     *
     * This function is used to compare equality of two base models, which are
     * equal if they have the same id
     */
    static func == (lhs: DIBaseModel, rhs: DIBaseModel) -> Bool {
        return (lhs.id ?? "") == (rhs.id ?? "")
    }
    
}

