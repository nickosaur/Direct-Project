//
//  DIEvent.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEvent.swift
 *
 * This file contains methods relating to editing events. In Direct, an Event is a social
 * gathering which one user will create an informational post about, allowing all other
 * users to view details about the event so that they may choose to express interest
 * in attending the event, and afterwards to be able to add their own content to the
 * event should they be in attendance.
 */

import Foundation
import GeoFire
import FirebaseDatabase

// key information for firebase storage
fileprivate struct DIEventKey{
    static let root = "events"
    static let title = "title"
    static let descriptionText = "descriptionText"
    static let location = "location"
    static let startTimeStamp = "startTimeStamp"
    static let endTimeStamp = "endTimeStamp"
    static let name = "name" // location.name
    static let cooridinate = "cooridinate"
    static let lat = "lat"
    static let long = "long"
    static let rsvpsUsers = "rsvpsUsers"
    static let visitedUsers = "visitedUsers"
    static let startDateStringUTC = "startDateStringUTC"
    static let categoryList = "categoryList" // what's stored in the database will be "movie, music, food"
    
    // moment child
    static let momentRoot = "moments"
    static let caption = "caption"

    // share
    static let videoPath = "videoPath"
    static let coverPath = "coverPath"
    static let userKey = "user"
    static let createdTime = "createdTime"
}

// one method of sorting events: relational time, then location
enum DIEventSortOption {
    case upcoming
    case nearby
}

// another method of sorting events: strictly relational time
enum DIEventStartDateOption {
    case past
    case upcoming
}

class DIEvent: DIBaseModel {
    static let DICheckInAllowedDistance: CLLocationDistance = 2000 // the threshold for user to check in, measure in meter
    // Event
    lazy var dict = [String: Any]()
    // event title
    var title: String? {
        return self.dict[DIEventKey.title] as? String
    }
    
    // description of event
    var descriptionText: String? {
        return self.dict[DIEventKey.descriptionText] as? String
    }
    
    // path to video link, if one exists
    var videoPath: URL? {
        guard let path = self.dict[DIEventKey.videoPath] as? String else {
            return nil
        }
        return URL(string: path)
    }
    
    // path to cover image
    var coverPath: String? {
        return self.dict[DIEventKey.coverPath] as? String
    }
    
    // event begin time
    var startTimeStamp: TimeInterval? {
        return self.dict[DIEventKey.startTimeStamp] as? TimeInterval
    }
    
    // event end time
    var endTimeStamp: TimeInterval? {
        return self.dict[DIEventKey.endTimeStamp] as? TimeInterval
    }
    
    // time event was created on application
    var createdTime: TimeInterval? {
        return self.dict[DIEventKey.createdTime] as? TimeInterval
    }
    
    // location of event
    var location: DILocation? {
        if let dict = self.dict[DIEventKey.location] as? [String: Any] {
            return DILocation(dict: dict)
        }
        return nil
    }
    
    // whether event is happening in the future
    var isUpcoming: Bool! {
        guard let startTime = self.dict[DIEventKey.startTimeStamp] as? TimeInterval else {
            return false
        }
        if startTime > Date().timeIntervalSince1970 {
            return true
        }
        return false
    }
    
    // whether event has already began
    var isLive: Bool! {
        guard let startTime = self.dict[DIEventKey.startTimeStamp] as? TimeInterval else {
            return false
        }
        guard let endTime = self.dict[DIEventKey.endTimeStamp] as? TimeInterval else {
            return false
        }
        let now = Date().timeIntervalSince1970
        if startTime < now && endTime > now {
            return true
        }
        return false
    }
    
    // whether event has ended
    var isEneded: Bool! {
       return !self.isUpcoming && !self.isLive
    }
    
    // key of event creator
    var userKey: String {
        return self.dict[DIEventKey.userKey] as? String ?? ""
    }

    var user: DIUser?
    
    // grab any associated event moments
    var moments: [DIMoment]? {
        get {
            if let momentIdDictPairs = self.dict[DIEventKey.momentRoot] as? [String: [String: Any]] {
                return DIMoment.transform(idDictionaryPair: momentIdDictPairs) // and sort moments by created time
            }
            return nil
        }
    }
    
    // all users who have RSVP'd to event
    var rsvpsUsers: [String: Double] {
        return (self.dict[DIEventKey.rsvpsUsers] as? [String: Double]) ?? [:]
    }
    
    // all users who have checked in to event
    var visitedUsers: [String: Double] {
        return (self.dict[DIEventKey.visitedUsers] as? [String: Double]) ?? [:]
    }
    
    // list of associated categories
    var categoryList: Set<String> {
        guard let listString = self.dict[DIEventKey.categoryList] as? String else {
            return []
        }
        return Set(listString.components(separatedBy: ", "))
    }
    
    // true when the event contains the video
    var isVideoEvent: Bool {
        return self.videoPath != nil ? true : false
    }
    
    // initialize event from it's ID
    init(id: String, dict: [String: Any]) {
        super.init()
        self.id = id
        self.dict = dict
    }
    
   /* fetchStartDates
    *
    * This function is used to retrieve the start dates of all events, so that
    * this information may be used to sort through events.
    */
    class func fetchStartDates(option: DIEventStartDateOption, completionHanlder callback: @escaping ([String]?) -> Void) {
        let ref = DIEvent.DatabaseReference.ref.child("event_start_date_fetch")
        ref.observeSingleEvent(of: .value) { (snapShots) in
            let dates = datesTransform(snapshot: snapShots)
            if option == .past {
                let filtedDate = dates?.filter({ (date) -> Bool in
                    return date <= getCurrentUTCDateString()
                })
                callback(filtedDate)
            } else {
                let filtedDate = dates?.filter({ (date) -> Bool in
                    return date >= getCurrentUTCDateString()
                })
                callback(filtedDate)
            }
        }
    }
    
    /* shareMoment
     *
     *  Allow the current authenticated user who has already checked in at the event and share their moment
     *  After finish sharing, a moment should be added to the given event
     */
    func shareMoment(caption: String, videoPath: String = "", coverPath: String = "", completionHanlder callback: @escaping (DIMoment?) -> Void) {
        guard let currentUser = DIAuth.shareFirebaseAuth.currentUser else {
            return
        }
        guard let eventId = self.id else {
            return
        }
        let now = Date().timeIntervalSince1970
        var dict: [String: Any] = [
            DIEventKey.userKey: currentUser.uid,
            DIEventKey.caption: caption,
            DIEventKey.createdTime: now
        ]
        if !videoPath.isEmpty {
            dict[DIEventKey.videoPath] = videoPath
        }
        if !coverPath.isEmpty {
            dict[DIEventKey.coverPath] = coverPath
        }
        
        let ref = DIEvent.DatabaseReference.ref.child(DIEventKey.root + "/" + eventId + "/" + DIEventKey.momentRoot).childByAutoId()
        ref.setValue(dict) { (error, reference) in
            if error == nil {
                let moment = DIMoment(id: reference.key, dict: dict)
                self.updateMoments(withMoment: moment)
                callback(moment)
            } else {
                callback(nil)
            }
        }
    }
    
    /* rsvp
     *
     * RSVP a current user the event
     *  event from callback not nil when update succeed
     */
    func rsvp(completionHandler callback: @escaping (DIEvent?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            callback(nil)
            return
        }
        guard let userId = currentUser.id, let eventId = self.id else {
            return
        }
        
        let now = Date().timeIntervalSince1970
        let updateObject: [String: Any] = [
            "/\(DIUser.userRootKey)/\(userId)/\(DIUser.rsvpEventsKey)/\(eventId)": now,
            "/\(DIEventKey.root)/\(eventId)/\(DIEventKey.rsvpsUsers)/\(userId)": now
        ]
        DIEvent.DatabaseReference.ref.updateChildValues(updateObject) { (error, ref) in
            if error == nil {
                currentUser.updateRsvp(action: .add, forEvent: self, updateTime: now)
                callback(self)
            } else {
                callback(nil)
            }
        }
    }
    
    /* unrsvp
     *
     * UNRSVP a current user the event
     *  event from callback not nil when update succeed
     */
    func unrsvp(completionHandler callback: @escaping (DIEvent?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            callback(nil)
            return
        }
        guard let userId = currentUser.id, let eventId = self.id else {
            return
        }
        
        let updateObject: [String: Any] = [
            "/\(DIUser.userRootKey)/\(userId)/\(DIUser.rsvpEventsKey)/\(eventId)": NSNull(),
            "/\(DIEventKey.root)/\(eventId)/\(DIEventKey.rsvpsUsers)/\(userId)": NSNull()
        ]
        DIEvent.DatabaseReference.ref.updateChildValues(updateObject) { (error, ref) in
            if error == nil {
                currentUser.updateRsvp(action: .delete, forEvent: self)
                callback(self)
            } else {
                callback(nil)
            }
        }
    }
    
    
    /* checkIn
     *
     *  Check in a current user the event
     *  event from callback not nil when update succeed
     */
    func checkIn(completionHandler callback: @escaping (DIEvent?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            callback(nil)
            return
        }
        guard let userId = currentUser.id, let eventId = self.id else {
            return
        }
        
        let now = Date().timeIntervalSince1970
        let updateObject: [String: Any] = [
            "/\(DIUser.userRootKey)/\(userId)/\(DIUser.visitedEventsKey)/\(eventId)": now,
            "/\(DIEventKey.root)/\(eventId)/\(DIEventKey.visitedUsers)/\(userId)": now
        ]
        DIEvent.DatabaseReference.ref.updateChildValues(updateObject) { (error, ref) in
            if error == nil {
                currentUser.updateVisited(action: .add, forEvent: self, updateTime: now)
                callback(self)
            } else {
                callback(nil)
            }
        }
    }
    
    /* unCheckIn
     *  UNCheck-in a current user the event
     *  event from callback not nil when update succeed
     */
    func unCheckIn(completionHandler callback: @escaping (DIEvent?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            callback(nil)
            return
        }
        guard let userId = currentUser.id, let eventId = self.id else {
            return
        }
        
        let updateObject: [String: Any] = [
            "/\(DIUser.userRootKey)/\(userId)/\(DIUser.visitedEventsKey)/": NSNull(),
            "/\(DIEventKey.root)/\(eventId)/\(DIEventKey.visitedUsers)/": NSNull()
        ]
        DIEvent.DatabaseReference.ref.updateChildValues(updateObject) { (error, ref) in
            if error == nil {
                currentUser.updateVisited(action: .delete, forEvent: self)
                callback(self)
            } else {
                callback(nil)
            }
        }
    }
    
    
    
    
    /* isCheckInAllowed
     *
     * use the current location to see if check-in availabe
     */
    func isCheckInAllowed() -> Bool {
        // check whether the event is happening to allow check in
        if self.isLive {
            guard let currentLocation = DILocationManager.getCurrentLocation() else {
                // no current location available
                return false
            }
            guard let eventLocation = self.location?.clLocation else {
                return false
            }
            let userDistance = currentLocation.distance(from: eventLocation)
            print(userDistance)
            return userDistance < DIEvent.DICheckInAllowedDistance
        }
        return false
    }
    
    /* updateMoments
     *
     * This function will update event moments from guests.
     */
    private func updateMoments(withMoment moment: DIMoment ) {
        if var momoentIdDictPairs = self.dict[DIEventKey.momentRoot] as? [String: [String: Any]]{
            guard let id = moment.id else {
                return
            }
            momoentIdDictPairs[id] = moment.dict
            self.dict[DIEventKey.momentRoot] = momoentIdDictPairs
        }
    }
    
    /* create
     *
     *  return an event object when successfully adding the event, nil if not
     */
    class func create(title: String, descriptionText: String, categories: [String], videoPath: String = "", coverPath: String = "", location: DILocation,  startDateStringUTC: String, startTimeStamp: TimeInterval, endTimeStamp: TimeInterval, completionBlock: @escaping (DIEvent?) -> Void) {
        guard let currentUser = DIAuth.auth.current else {
            return
        }
        let now = Date().timeIntervalSince1970
        guard let locationName = location.name else {
            return
        }
        guard let locationCo = location.coordinate else {
            return
        }
        let categoriesString = categories.joined(separator: ", ")
        
        var dict: [String: Any] = [
            DIEventKey.userKey: currentUser.id,
            DIEventKey.title: title,
            DIEventKey.startTimeStamp: startTimeStamp,
            DIEventKey.endTimeStamp: endTimeStamp,
            DIEventKey.location: [
                DIEventKey.name: locationName,
                DIEventKey.cooridinate: [
                    DIEventKey.lat: locationCo.latitude,
                    DIEventKey.long: locationCo.longitude
                ]
            ],
            DIEventKey.descriptionText: descriptionText,
            DIEventKey.createdTime: now,
            DIEventKey.startDateStringUTC: startDateStringUTC
        ]
        
        if !videoPath.isEmpty {
            dict[DIEventKey.videoPath] = videoPath
        }
        if !coverPath.isEmpty {
            dict[DIEventKey.coverPath] = coverPath
        }
        
        if !categoriesString.isEmpty {
            dict[DIEventKey.categoryList] = categoriesString
        }

        let itemRefer = DatabaseReference.ref.child(DIEventKey.root).childByAutoId()
        guard let userId = currentUser.id else {
            return
        }
        
        let updateObject: [String: Any] = [
            "/\(DIEventKey.root)/\(itemRefer.key)": dict,
            "/\(DIUser.userRootKey)/\(userId)/\(DIUser.hostedEventsKey)/\(itemRefer.key)": now
        ]
       
        DIEvent.DatabaseReference.ref.updateChildValues(updateObject) { (error, ref) in
            if error == nil {
                guard let loc = location.clLocation else {
                    print(error?.localizedDescription ?? "Error occured while saving location")
                    return
                }
                DIGeoFire.eventReference(eventStartDateUTCString: startDateStringUTC).setLocation(loc, forKey: itemRefer.key) { (error) in
                    if (error != nil) {
                        print(error?.localizedDescription ?? "Error occured while saving location")
                    } else {
                        print("Saved location successfully!")
                    }
                }
                DIEvent.fetchEvent(withKey: itemRefer.key, completionBlock: { (event) in
                    completionBlock(event)
                })
            } else {
                completionBlock(nil)
            }
        }
    }
    
    // if the App can't retrieve the user's location, use this method to return five random events, or alertnatively, set the center using San Francisco
    class func fetchEvents(completionBlock callback: @escaping ([DIEvent]?) -> Void) {
        // default to fetch 5 events
        DatabaseReference.ref.child(DIEventKey.root).queryLimited(toFirst: 20).observeSingleEvent(of: .value, with: {
            snapshot in
            guard let events = DIEvent.transform(snapshot: snapshot) else {
                callback(nil)
                return
            }
            let sortedEvents = events.sorted(by: { (e1, e2) -> Bool in
                return e1.endTimeStamp ?? 0 > e2.endTimeStamp ?? 0
            })
            DIEvent.fetchUserBatch(forEvents: sortedEvents, completionBlock: callback)
        })
    }
    
    
    //returns a GeoFire query of events that are nearby
    class func queryByRadius(geoFire:GeoFire,centerLat:Double, centerLong:Double, radius:Double) -> (GFQuery) {
        let center = CLLocation(latitude: centerLat, longitude: centerLong)
        // Query locations at the center with a radius measured in kms
        let circleQuery = geoFire.query(at: center, withRadius: radius)
        return circleQuery!
    }
    
    // TODO:
    /*
     * Fetches nearby events from the current location with the specified radius.
     * Can potentially make the function more general by adding long and lat as parameters
     * and then query from that long and lat instead of grabbing current location.
     * The radius is measured in kilometers
     */
    class func fetchEventNearby(radius:Double, sortOption: DIEventSortOption = .nearby, completionBlock callback: @escaping ([DIEvent]?) -> Void) {
        guard let currentLocation = DILocationManager.getCurrentLocation() else {
            // default to fetch event
            DIEvent.fetchEvents(completionBlock: callback)
            return
        }
        
        //array that will store IDs of events that match the query
        var nearbyEventIDs = [String]()
        let geoFire = DIGeoFire.eventReference(eventStartDateUTCString: getCurrentUTCDateString())
        let circleQuery = queryByRadius(geoFire: geoFire, centerLat: currentLocation.coordinate.latitude, centerLong: currentLocation.coordinate.longitude, radius:radius)
        circleQuery.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            nearbyEventIDs.append(key)
            print(key)
        })
        
        let taskGroup = DispatchGroup()
        var result = [DIEvent]()
        
        circleQuery.observeReady({
            DispatchQueue.global(qos: .userInitiated).async {
                for eventID in nearbyEventIDs {
                    taskGroup.enter()
                    DIEvent.fetchEvent(withKey: eventID, completionBlock: { (event) in
                        if let event = event {
                            result.append(event)
                        }
                        taskGroup.leave()
                    })
                }
                taskGroup.wait()
                DispatchQueue.main.async {
                    var sortedResult: [DIEvent]?
                    if sortOption == .upcoming {
                        sortedResult = result.sorted(by: { (e_1, e_2) -> Bool in
                            return e_1.startTimeStamp ?? 0 < e_2.startTimeStamp ?? 0
                        })
                    } else {
                        sortedResult = result.sorted(by: { (e_1, e_2) -> Bool in
                            return (e_1.location?.clLocation?.distance(from: currentLocation) ?? 0) < (e_2.location?.clLocation?.distance(from: currentLocation) ?? 0)
                        })
                    }
                    callback(sortedResult)
                }
            }
        })
    }
 
    /* fetchUserBatch
     *
     * This function will retrieve the users who are associated with the given events.
     */
    class func fetchUserBatch(forEvents events: [DIEvent], completionBlock: @escaping ([DIEvent]) -> Void) {
        let taskGroup = DispatchGroup()
        for event in events {
            taskGroup.enter()
            DIUser.fetchUser(withKey: event.userKey, completionBlock: { (user) in
                event.user = user
                taskGroup.leave()
            })
        }
        DispatchQueue.global(qos: .userInitiated).async {
            taskGroup.wait()
            DispatchQueue.main.async {
                completionBlock(events)
            }
        }
    }
    
    /* fetchEventLocationBatch
     *
     * This function will retrieve the locations for the given events, which will allow us
     * to sort through a given list of event based on relevancy to a user.
     */
    class func fetchEventLocationBatch(forEvents events: [DIEvent], completionBlock: @escaping ([DIEvent]) -> Void) {
        let taskGroup = DispatchGroup()
        for event in events {
            taskGroup.enter()
            DIUser.fetchUser(withKey: event.userKey, completionBlock: { (user) in
                event.user = user
                taskGroup.leave()
            })
        }
        DispatchQueue.global(qos: .userInitiated).async {
            taskGroup.wait()
            DispatchQueue.main.async {
                completionBlock(events)
            }
        }
    }
    
    /** fetch single event by id
     */
    class func fetchEvent(withKey key: String, completionBlock callback: @escaping (DIEvent?) -> Void) {
        DatabaseReference.ref.child(DIEventKey.root + "/" + key).observeSingleEvent(of: .value, with: {
            snapshot in
            if let dict = snapshot.value as? [String: Any] {
                let event = DIEvent(id: key, dict: dict)
                DIUser.fetchUser(withKey: event.userKey, completionBlock: { (user) in
                    if let user = user {
                        event.user = user
                        callback(event)
                    } else {
                        callback(nil)
                    }
                })
            } else {
                callback(nil)
            }
        })
    }
    
    /** convert the snapshot to an array of DIEvent
     *  @param snapshot
     *  @return an array of events
     */
    class func transform(snapshot : DataSnapshot) -> [DIEvent]?{
        if let snapshotsValues = snapshot.value as? [String: [String : Any]] {
            let events = snapshotsValues.map({ (arg: (id: String, info: [String : Any])) -> DIEvent in
                let (id, info) = arg
                let event = DIEvent(id: id, dict: info)
                return event
            })
            return events
        }
        return nil
    }
    
    /* datesTransform
     *
     * This function is used to map moments to to their corresponding dates, so that
     * we can use this information to sort.
     */
    class func datesTransform(snapshot : DataSnapshot) -> [String]?{
        if let snapshotsValues = snapshot.value as? [String: [String : Any]] {
            let dates = snapshotsValues.map({ (arg: (id: String, info: [String : Any])) -> String in
                let (id, info) = arg
                return id
            })
            return dates
        }
        return nil
    }

}

/* DIMoment
 *
 * This class is used to define each individual event moment under an event. In
 * Direct, event moments are posted by guests, and they include media content
 * in addition to a description about what they’ve posted. To add these moments,
 * the user must be checked-in to the event, meaning they must be within a
 * specified radius of the event.
 */
class DIMoment: DIBaseModel {
    lazy var dict = [String: Any]()
    
    // user info from firebase
    var userKey: String? {
        return self.dict[DIEventKey.userKey] as? String
    }
    
    // caption
    var caption: String? {
        return self.dict[DIEventKey.caption] as? String
    }
    
    // path to video content, if applicable
    var videoPath: URL? {
        guard let path = self.dict[DIEventKey.videoPath] as? String else {
            return nil
        }
        return URL(string: path)
    }
    
    // path to cover image
    var coverPath: String? {
        return self.dict[DIEventKey.coverPath] as? String
    }
    
    // current user
    var user: DIUser?
    
    // if user posted a video
    var hasVideoAttachment: Bool {
        return self.videoPath != nil
    }
    
    // when moment was created
    var createdTime: Date {
        return Date(timeIntervalSince1970: self.dict[DIEventKey.createdTime] as? TimeInterval ?? 0)
    }
    
    // intialize a moment from ID
    init(id: String, dict: [String: Any]) {
        super.init()
        self.id = id
        self.dict = dict
    }
    
    /* fetchUser
     *
     * This function is used to get the current user. It uses the key to attempt and access
     * this information from firebase.
     */
    func fetchUser(completionHandler callback: @escaping (DIUser?) -> Void) {
        if let userKey = self.userKey {
            DIUser.fetchUser(withKey: userKey, completionBlock: { (user) in
                self.user = user
                callback(user)
            })
        } else {
            callback(nil)
        }
    }
    
    /** convert the momentId and dictionary to an array of DIMoment
     *  @return an array of moments
     */
    class func transform(idDictionaryPair : [String: [String: Any]]) -> [DIMoment]?{
        let moments = idDictionaryPair.map({ (arg: (id: String, info: [String : Any])) -> DIMoment in
            let (id, info) = arg
            let moment = DIMoment(id: id, dict: info)
            return moment
        })
        return moments
    }
}
