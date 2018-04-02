//
//  DIDeviceToken.swift
//  Direct
//
//  Created by Kesong Xie on 11/2/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIDeviceToken.swift
 *
 * This file is used to connect the device with the database reference, if the
 * device is associated with a user, so that the application can send notifications
 * to the device if allowed.
 */

import Firebase
import FirebaseAuth
import FirebaseDatabase

// device key for firebase
fileprivate struct DIDeviceTokenKey{
    static let root = "device_token"
}

class DIDeviceToken: DIBaseModel {
    
    /* setDeviceToken
     *
     * Gets the user information from the database if possible. Returns a string
     * representation of the device token.
     */
    class func setDeviceToken(completionBlock callback: ((String?) -> Void)?){
        guard let userKey = DIAuth.shareFirebaseAuth.currentUser?.uid else{
            callback?(nil)
            return
        }
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        print("fcm token is \(fcmToken)")
        let ref = DatabaseReference.ref.child(DIDeviceTokenKey.root + "/" + userKey)
        ref.setValue(fcmToken) { (error, reference) in
            if error == nil {
                callback?(fcmToken)
            } else {
                callback?(nil)
            }
        }
    }
}
