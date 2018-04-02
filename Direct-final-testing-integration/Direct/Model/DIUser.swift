//
//  DIUser.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIUser.swift
 *
 * This file is used to deal with the information associated with a current user, and to link
 * this information with the firebase storage. Information which will be stored about a user
 * for the purposes of Direct will include their name, email address, profile image (optional),
 * and potentially additional event related information (their interests in terms of event
 * categories and events they have expressed interest in).
 */

import FirebaseAuth
import FirebaseDatabase

// information for/from database
fileprivate struct DIUserKey{
    static let root = "users"
    static let fullname = "fullname"
    static let profileImagePath = "profileImagePath"
    static let email = "email"
    static let rsvpEvents = "rsvpsEvents"
    static let visitedEvents = "visitedEvents"
    static let hostedEvents = "hostedEvents"
    static let eventPreferences = "eventPreferences"
    static let bio = "bio"
    static let isOrganizer = "isOrganizer"
    static let defaultLocation = "defaultLocation"
    static let locationName = "name"
    static let locationCoordinate = "coordinate"
    static let lat = "lat"
    static let long = "long"

}

// for changing RSVP status
enum DIRSVPAction {
    case add
    case delete
}

// for changing check in status
enum DICheckInAction {
    case add
    case delete
}

class DIUser: DIBaseModel {
    // public  keys
    static let rsvpEventsKey = DIUserKey.rsvpEvents
    static let visitedEventsKey = DIUserKey.visitedEvents
    static let hostedEventsKey = DIUserKey.hostedEvents
    static let userRootKey = DIUserKey.root
    
    
    lazy var dict = [String: Any]()
    
    /* init
     *
     * This function is used to initialize a new object.
     */
    init(id: String, dict: [String: Any]) {
        super.init()
        self.id = id
        self.dict = dict
    }
    
    // user’s name
    var fullname: String? {
        return self.dict[DIUserKey.fullname] as? String
    }
    
    // biography given by user
    var bio: String? {
        return self.dict[DIUserKey.bio] as? String
    }
    
    // email address
    var email: String? {
        return self.dict[DIUserKey.email] as? String
    }
    
    var isOrganizer: Bool? {
        return self.dict[DIUserKey.isOrganizer] as? Bool
    }
    
    // path to user’s profile image
    var profileImageURL: URL? {
        return URL(string: self.dict[DIUserKey.profileImagePath] as? String ?? "")
    }
    
    // categories user has indicated interest in
    var eventPreferencesCategoryString: String? {
        return self.dict[DIUserKey.eventPreferences] as? String
    }
    
    // categories as list
    var eventPreferencesCategoryList: Set<String> {
        guard let listString = self.eventPreferencesCategoryString else {
            return []
        }
        return Set(listString.components(separatedBy: ", "))
    }
    
    // the value of the dictionary is the TimeInterval when the user rsvp
    var rsvpEvents: [String: TimeInterval]! {
        get {
            return (self.dict[DIUserKey.rsvpEvents] as? [String: TimeInterval]) ?? [:]
        }
    }
    
    // events the user visited in past
    var visitedEvents: [String: TimeInterval]! {
        get {
            return (self.dict[DIUserKey.visitedEvents] as? [String: TimeInterval]) ?? [:]
        }
    }
    
    // events the user hosted
    var hostedEvents: [String: TimeInterval]! {
        get {
            return (self.dict[DIUserKey.hostedEvents] as? [String: TimeInterval]) ?? [:]
        }
    }
    
    // hold all past & present events
    lazy var rsvpLoadedEvents = [DIEvent]()
    lazy var vistedLoadedEvents = [DIEvent]()
    lazy var hostedLoadedEvents = [DIEvent]()

    /** update the current user profile, callback user not nil if update sucessfully
     */
    class func updateProfile(fullname: String, introduction: String, preferredCategory: String, profileImageData: Data?,  defaultLocation: DILocation?, completionBlock callback: @escaping (DIUser?) -> Void) {
        // helper function
        func updateWithObject(object: [String: Any], completionBlock callback: @escaping (DIUser?) -> Void) {
            guard let currentUserId = DIAuth.auth.current?.id else {
                return
            }
            DIEvent.DatabaseReference.ref.updateChildValues(object) { (error, ref) in
                if error == nil {
                    DIUser.fetchUser(withKey: currentUserId, completionBlock: { (user) in
                        DIAuth.auth.current = user
                        callback(user)
                    })
                } else {
                    callback(nil)
                }
            }
        }
        
        guard let currentUserId = DIAuth.auth.current?.id else {
            return
        }

        var updateObject: [String: Any] = [
            "/\(DIUser.userRootKey)/\(currentUserId)/\(DIUserKey.bio)": introduction,
            "/\(DIUser.userRootKey)/\(currentUserId)/\(DIUserKey.fullname)": fullname,
            "/\(DIUser.userRootKey)/\(currentUserId)/\(DIUserKey.eventPreferences)": preferredCategory
        ]
        if let defaultLocation = defaultLocation {
            updateObject["/\(DIUser.userRootKey)/\(currentUserId)/\(DIUserKey.defaultLocation)"] = [
                DIUserKey.locationName: defaultLocation.name ?? "",
                DIUserKey.locationCoordinate: [
                    DIUserKey.lat: defaultLocation.coordinate?.latitude ?? 0,
                    DIUserKey.long: defaultLocation.coordinate?.longitude ?? 0
                ]
            ]
        }
        if let data = profileImageData {
            let imageModel = DIImageModel(imageData: data)
            imageModel.sync(completionBlock: { (model) in
                if let path = model.fetchURLString {
                    updateObject["/\(DIUser.userRootKey)/\(currentUserId)/\(DIUserKey.profileImagePath)"] = path
                    updateWithObject(object: updateObject, completionBlock: callback)
                }
            })
        } else {
            updateWithObject(object: updateObject, completionBlock: callback)
        }
    }
    
    
    // user not nil from the callback if save successfully
    func sync(withImageData imageData: Data? = nil, completionHandler callback: @escaping (DIUser?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            return
        }
        let ref = DIUser.DatabaseReference.ref.child(DIUserKey.root).child(currentUser.id)
        if imageData != nil {
            let imageModel = DIImageModel(imageData: imageData!)
            imageModel.sync(completionBlock: { (model) in
                if let path = model.fetchURLString {
                    let info: [String : Any] = [
                        DIUserKey.bio: self.bio ?? "",
                        DIUserKey.email: self.email ?? "",
                        DIUserKey.isOrganizer: self.isOrganizer ?? false,
                        DIUserKey.fullname: self.fullname ?? "",
                        DIUserKey.eventPreferences: self.eventPreferencesCategoryString ?? "",
                        DIUserKey.profileImagePath: path
                    ]
                    let oldProfileURL = self.profileImageURL
                    ref.setValue(info) { (error, reference) in
                        if error == nil {
                            let user = DIUser(id: reference.key, dict: info)
                            DIAuth.auth.current = user
                            // delete the old profile image from firebase storage
                            let oldImageModel = DIImageModel(fetchedURL: oldProfileURL)
                            oldImageModel.sync(option: .delete) { _ in
                                callback(user)
                            }
                        } else {
                            callback(nil)
                        }
                    }
                } else {
                    callback(nil)
                }
            })
        } else {
            let info: [String : Any] = [
                DIUserKey.bio: self.bio ?? "",
                DIUserKey.fullname: self.fullname ?? "",
                DIUserKey.isOrganizer: self.isOrganizer ?? false,
                DIUserKey.email: self.email ?? "",
                DIUserKey.eventPreferences: self.eventPreferencesCategoryString ?? "",
                DIUserKey.profileImagePath: self.profileImageURL?.absoluteString ?? ""
            ]
            ref.setValue(info) { (error, reference) in
                if error == nil {
                    let user = DIUser(id: reference.key, dict: info)
                    DIAuth.auth.current = user
                    callback(user)
                }
            }
        }
    }
    
    // need to call sync when the  user confirm saving
    func setEventPreferencesString(categories: [String]) {
        let selectedCategoriesString = categories.joined(separator: ", ")
        self.dict[DIUserKey.eventPreferences] = selectedCategoriesString
    }
    
    
    /* updateRSVP
     *
     * This function is used when the user changes the status of their RSVP.
     */
    func updateRsvp(action: DIRSVPAction, forEvent event: DIEvent, updateTime: TimeInterval = 0) {
        guard let eventId = event.id else {
            return
        }
        var rsvpDict = (self.dict[DIUserKey.rsvpEvents] as? [String: TimeInterval]) ?? [:]
        if action == .add {
            rsvpDict[eventId] = updateTime
        } else {
            if rsvpDict[eventId] != nil {
                rsvpDict.removeValue(forKey: eventId)
            }
        }
        self.dict[DIUserKey.rsvpEvents] = rsvpDict
        // set the most up-to-date user as the current user and save it to default
        DIAuth.cacheCurrentUser(user: self)
    }
    
    /* isUserRsvp
     *
     * Checks whether the user has RSVP’d to the given event.
     */
    func isUserRsvp(forEvent event: DIEvent) -> Bool{
        guard let eventId = event.id else {
            return false
        }
        return self.rsvpEvents[eventId] != nil
    }
    
    /** fetch the completed objects of the rsvp events
     */
    func fetchRSVPEvents(completionBlock callback: @escaping ([DIEvent]?) -> Void) {
        let taskGroup = DispatchGroup()
        var result = [DIEvent]()
        DispatchQueue.global(qos: .userInitiated).async {
            for (eventKey, _) in self.rsvpEvents {
                taskGroup.enter()
                DIEvent.fetchEvent(withKey: eventKey, completionBlock: { (event) in
                    if let event = event {
                        result.append(event)
                    }
                    taskGroup.leave()
                })
            }
         
            taskGroup.wait()
            DispatchQueue.main.async {
                self.rsvpLoadedEvents = result
                callback(result)
            }
        }
    }
    
    /** fetch hosted events
     */
    func fetchHostedEvents(completionBlock callback: @escaping ([DIEvent]?) -> Void) {
        let taskGroup = DispatchGroup()
        var result = [DIEvent]()
        DispatchQueue.global(qos: .userInitiated).async {
            for (eventKey, _) in self.hostedEvents {
                taskGroup.enter()
                DIEvent.fetchEvent(withKey: eventKey, completionBlock: { (event) in
                    if let event = event {
                        result.append(event)
                    }
                    taskGroup.leave()
                })
            }
            
            taskGroup.wait()
            DispatchQueue.main.async {
                let sortedResult = result.sorted(by: { (e_1, e_2) -> Bool in
                    return e_1.startTimeStamp ?? 0 < e_2.startTimeStamp ?? 0
                })
                self.hostedLoadedEvents = sortedResult
                callback(sortedResult)
            }
        }
    }
    
    /** refresh the current user profile
     */
    func refreshProfile(completionHanlder callback: @escaping (DIUser?) -> Void) {
        DIUser.fetchUser(withKey: self.id) { (user) in
            DIAuth.auth.current = user
            callback(user)
        }
    }
    
    // check-in
    func updateVisited(action: DICheckInAction, forEvent event: DIEvent, updateTime: TimeInterval = 0) {
        guard let eventId = event.id else {
            return
        }
        var visitedDict = (self.dict[DIUserKey.visitedEvents] as? [String: TimeInterval]) ?? [:]
        if action == .add {
            visitedDict[eventId] = updateTime
        } else {
            if visitedDict[eventId] != nil {
                visitedDict.removeValue(forKey: eventId)
            }
        }
        self.dict[DIUserKey.visitedEvents] = visitedDict
        // set the most up-to-date user as the current user and save it to default
        DIAuth.cacheCurrentUser(user: self)
    }
    
    // check whether a given user is check in at a given event or not
    func isUserCheckedIn(forEvent event: DIEvent) -> Bool{
        guard let eventId = event.id else {
            return false
        }
        return self.visitedEvents[eventId] != nil
    }
    
    /** fetch the completed objects of the visited events
     */
    func fetchVisitedEvents(completionBlock callback: @escaping ([DIEvent]?) -> Void) {
        let taskGroup = DispatchGroup()
        var result = [DIEvent]()
        DispatchQueue.global(qos: .userInitiated).async {
            for (eventKey, _) in self.visitedEvents {
                taskGroup.enter()
                DIEvent.fetchEvent(withKey: eventKey, completionBlock: { (event) in
                    if let event = event {
                        result.append(event)
                    }
                    taskGroup.leave()
                })
            }
            
            taskGroup.wait()
            DispatchQueue.main.async {
                self.vistedLoadedEvents = result
                callback(result)
            }
        }
    }
    
    
    
    /** return a set of intersected category when a given event matches the user preferences
     */
    func getEventMatchesPreferences(event: DIEvent) -> Set<String> {
        let categoryList = self.eventPreferencesCategoryList
        return categoryList.intersection(event.categoryList)
    }
    

    /** set the current user information, including firstname, lastname
     *  @param fullname of the user
     *  @param completionBlock the comletion block to be executed after the fetching
     */
    class func setCurrentUserInfo(fullname : String, email: String = "", profilePath: String = "", isOrganizer: Bool = false, completionBlock callback: @escaping (DIUser?) -> Void){
        guard let currentUser = Auth.auth().currentUser else{
            callback(nil)
            return
        }
        let ref = DatabaseReference.ref.child(DIUserKey.root).child(currentUser.uid)
       
        var info: [String : Any] = [
            DIUserKey.fullname: fullname,
            DIUserKey.isOrganizer: isOrganizer
        ]
        if !email.isEmpty {
             info[DIUserKey.email] = email
        }
        if !profilePath.isEmpty {
            info[DIUserKey.profileImagePath] = profilePath
        }
        
        ref.setValue(info) { (error, reference) in
            if error == nil {
                let user = DIUser(id: reference.key, dict: info)
                callback(user)
            }
        }
    }

    /* fetchUser
     *
     * This function retrieves a user’s information from the database with the given key.
     */
    class func fetchUser(withKey key: String, completionBlock callback: @escaping (DIUser?) -> Void) {
        DatabaseReference.ref.child(DIUserKey.root + "/" + key).observeSingleEvent(of: .value, with: {
            snapshot in
            if let dict = snapshot.value as? [String: Any] {
                let user = DIUser(id: key, dict: dict)
                callback(user)
            } else {
                callback(nil)
            }
        })
    }
    
    

}
