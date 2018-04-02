//
//  DIAuth.swift
//  Direct
//
//  Created by Xie kesong on 10/18/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIAuth.swift
 *
 * This file is used for all user authorization. It checks with the database and
 * pulls user information for a current authenticated user, and will also write
 * user information to the database when a new user signs up for an account.
 */

import Foundation
import FirebaseAuth

// key components for firebase storage
fileprivate struct DIAuthCacheKey {
    static let currentUser = "currentUser"
    static let userKey = "userKey"
    static let userDict = "userDict"
}

// information saved when signing up for account
struct DISignUpInfo {
    var isOrganizer: Bool = false
    var fullname: String = ""
    var profilePictureImageData: Data? = nil
    var email: String = ""
    var password: String = ""
}

class DIAuth {
    static let shareFirebaseAuth = Auth.auth()

    static let auth = DIAuth()
    // this customized current user should be set after the user authenticated, using DIAuth.auth().current = DIUser(#rest of params)
    var current: DIUser? {
        get {
            return DIAuth.getCurrentCacheUser()
        }
        set (newValue) {
            if let updatedUser = newValue {
                DIAuth.cacheCurrentUser(user: updatedUser)
            } else {
                DIAuth.removeCurrentUserFromCache()
            }
        }
    }

    /* signUp
     *
     * This function will attempt to create a new user with the given information,
     * and will set the current user to the newly created account if the operation
     * was successful. Otherwise, it will print an error message if the account could
     * not be created.
     */
    class func signUp(withInfo info: DISignUpInfo, completionHandler callback: @escaping (DIUser?) -> Void) {
        // helper function for sign up
        func signUp(fullname: String, email: String, profilePath: String = "", isOrganizer: Bool = false) {
            DIUser.setCurrentUserInfo(fullname: fullname, email: email,  profilePath: profilePath, isOrganizer: isOrganizer) {
                user in
                if let user = user {
                    DIUser.fetchUser(withKey: user.id, completionBlock: { (loggedInUser) in
                        DIAuth.auth.current = loggedInUser
                        callback(loggedInUser)
                    })
                } else {
                    callback(nil)
                }
            }
        }
        
        let email = info.email
        let password = info.password
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let _ = user {
                // now the user is logged in
                let fullname = info.fullname
                let isOrganizer = info.isOrganizer
                if let imageData = info.profilePictureImageData {
                    // upload the profile picture first
                    let imageModel = DIImageModel(imageData: imageData)
                    imageModel.sync(completionBlock: { (model) in
                        // get the fetch url
                        guard let profilePath = model.fetchedURL?.absoluteString else {
                            callback(nil)
                            return
                        }
                        signUp(fullname: fullname, email: email, profilePath: profilePath, isOrganizer:isOrganizer)
                    })
                } else {
                    signUp(fullname: fullname, email: email, isOrganizer: isOrganizer)
                }
            } else {
                callback(nil)
                print(error?.localizedDescription ?? "")
            }
        }
    }
    
    /* signIn
     *
     * This function will attempt to sign in a user with the fields they have input at
     * the login screen. If the user has logged in with the proper credentials, then
     * their stored information and preferences shall be fetched as the current user.
     */
    class func signIn(email: String, password: String, completionHandler callback: @escaping (DIUser?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let user = user {
                DIUser.fetchUser(withKey: user.uid, completionBlock: { (loggedInUser) in
                    // save this user login credential to default
                    callback(loggedInUser)
                })
            } else {
                callback(nil)
            }
        }
    }

    /* signout
     *
     * This function will attempt to sign out the current authenticated user. If the user
     * is successfully signed out then they are no longer authorized to access the
     * current information. Otherwise, an error message will be displayed if there is
     * an issue with the sign out process.
     */
    class func signout(completionHandler callback: @escaping () -> Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            DIAuth.auth.current = nil
            callback()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    /* removeCurrentUserFromCache
     *
     * This will remove the current user’s information from the cache, so if the user
     * logs in again they will have to reload their information.
     */
    class func removeCurrentUserFromCache() {
        if DIApp.userDefault.object(forKey: DIAuthCacheKey.currentUser) != nil {
            DIApp.userDefault.removeObject(forKey: DIAuthCacheKey.currentUser)
        }
    }
    
    /* cacheCurrentUser
     *
     * This function will load information from the user into the cache, so that their
     * preferences will be loaded faster.
     */
    class func cacheCurrentUser(user: DIUser) {
        guard let userKey = user.id else {
            return
        }
        let userDict = user.dict
        let info: [String: Any] = [
            DIAuthCacheKey.userKey: userKey,
            DIAuthCacheKey.userDict: userDict
        ]
        DIApp.userDefault.set(info, forKey: DIAuthCacheKey.currentUser)
    }
    
    /* getCurrentCacheUser
     *
     * This function will attempt to get the user’s information from the cache, and
     * return their information if found.
     */
    class func getCurrentCacheUser() -> DIUser? {
        if let cacheUserInfo = DIApp.userDefault.object(forKey: DIAuthCacheKey.currentUser) as? [String: Any] {
            let id = cacheUserInfo[DIAuthCacheKey.userKey] as! String
            let userDict = cacheUserInfo[DIAuthCacheKey.userDict] as! [String: Any]
            return DIUser(id: id, dict: userDict)
        }
        return nil
    }
}
