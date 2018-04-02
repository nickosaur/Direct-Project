//
//  DINotification.swift
//  Direct
//
//  Created by Kesong Xie on 11/4/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DINotification.swift
 *
 * This file is used to handle the creation of notifications, based on information retrieved
 * from firebase storage.
 */

import FirebaseAuth
import FirebaseDatabase


/*  JSON structure
 *  notifications
 *      user_id_1
 *          notification_id_1
 *              event_key
 *              categoryLabel
 *              deliverTimestamp
 *          notification_id_2
 *              event_key
 *              categoryLabel
 *              deliverTimestamp
 *      user_id_2
 *
 */

// key inforomation for firebase
fileprivate struct DINotificationKey{
    static let root = "notifications"
    
    // all the fields below is under the value of a given user
    static let eventKey = "eventKey"
    static let notificationTypeLabel = "notificationTypeLabel" // a description of the type of the notification, ex "From your planned list", "Matched your "Art" preference"
    static let deliverTimestamp = "deliverTimestamp"
    static let type = "type"
}

// reasons for getting a notification
fileprivate struct DINotificationSupportedTypeString {
    static let planned = "planned"
    static let preference = "preference"
    static let suggestion = "suggestion"
}

// types of notifications
enum DINotificationType {
    case planned
    case preference(matchedCategories: Set<String>?)
    case suggestion
}

final class DINotification: DIBaseModel {
    lazy var dict = [String: Any]()
    
    // build the structure for any type of notification
    var type: DINotificationType {
        guard let typeString = self.dict[DINotificationKey.type] as? String else{
            return .suggestion
        }
        switch typeString {
        case DINotificationSupportedTypeString.planned:
            return .planned
        case DINotificationSupportedTypeString.preference:
            return .preference(matchedCategories: nil)
        default:
            return .suggestion
        }
    }
    
    // return label which explains why notification was recieved
    var notificationTypeLabel: String {
        return self.dict[DINotificationKey.notificationTypeLabel] as? String ?? ""
    }
    
    /* init
     *
     * This function is used to initialize a new object.
     */
    init(id: String, dict: [String: Any]) {
        super.init()
        self.id = id
        self.dict = dict
    }
    
    // event key
    var eventKey: String? {
        return self.dict[DINotificationKey.eventKey] as? String
    }
    
    // time notification was delivered
    var deliverTimestamp: TimeInterval? {
        return self.dict[DINotificationKey.deliverTimestamp] as? TimeInterval
    }
    
    var event: DIEvent?
    
    
    // fetch the notification for the authenticated user
    class func fetchNotification(completionBlock callback: @escaping ([DINotification]?) -> Void) {
        guard let currentUserId = DIAuth.auth.current?.id else {
            callback(nil)
            return
        }
        let itemRefer = DatabaseReference.ref.child("\(DINotificationKey.root)/\(currentUserId)")
        itemRefer.observeSingleEvent(of: .value,  with: {(snapshot) in
            guard let notifications = DINotification.transform(snapshot: (snapshot)) else {
                callback(nil)
                return
            }
            
            let taskGroup = DispatchGroup()
            DispatchQueue.global(qos: .userInitiated).async {
                for notification in notifications {
                    guard let eventKey = notification.eventKey else {
                        continue
                    }
                    taskGroup.enter()
                    DIEvent.fetchEvent(withKey: eventKey, completionBlock: { (event) in
                        if let event = event {
                            notification.event = event
                        }
                        taskGroup.leave()
                    })
                }
                
                taskGroup.wait()
                DispatchQueue.main.async {
                    callback(notifications)
                }
            }
        })
    }
    
    
    
    /** Add notification for current user, and the function determine what's the correct category for the notification
     *  and generate categoryLabel for the given notification
     */
    class func addNotification(forEvent event: DIEvent, completionBlock callback: (() -> Void)?) {
        guard let currentUserId = DIAuth.auth.current?.id else {
            return
        }
        
        // get the notification type
        let type = DINotification.getNotificationType(forEvent: event)
        var labelString = ""
        var typeString = ""
        switch type {
        case .planned:
            labelString = "From your planned list"
            typeString = DINotificationSupportedTypeString.planned
        case .preference(let categorySet):
            labelString = "Matched your \"" + (categorySet?.joined(separator: ", ") ?? "") + "\" preferences"
            typeString = DINotificationSupportedTypeString.preference
        case .suggestion:
            labelString = "Suggestion for you"
            typeString = DINotificationSupportedTypeString.suggestion
        }
        
        let dict: [String: Any] = [
            DINotificationKey.eventKey: event.id,
            DINotificationKey.deliverTimestamp: Date().timeIntervalSince1970,
            DINotificationKey.notificationTypeLabel: labelString,
            DINotificationKey.type: typeString
        ]
        
        let itemRefer = DatabaseReference.ref.child("\(DINotificationKey.root)/\(currentUserId)").childByAutoId()
        itemRefer.setValue(dict) { (error, reference) in
            callback?()
        }
    }
    
    /** get the notification type for current authenticated user
     */
    private class func getNotificationType(forEvent event: DIEvent) -> DINotificationType{
        guard let currentUser = DIAuth.auth.current else {
            return .suggestion
        }
        // determine the event type
        // see whether this given event is in the user's planned event list or not
        if currentUser.rsvpEvents[event.id] != nil {
            return .planned
        } else {
            // see whether this event matches the user preferences or not
            let macthes = currentUser.getEventMatchesPreferences(event: event)
            if !macthes.isEmpty {
                // found the matches
                return .preference(matchedCategories: macthes)
            } else {
                return .suggestion
            }
        }
    }
    
    /** convert the snapshot to an array of DINotification
     *  @param snapshot
     *  @return an array of notifications
     */
    class func transform(snapshot : DataSnapshot) -> [DINotification]?{
        if let snapshotsValues = snapshot.value as? [String: [String : Any]] {
            let notifications = snapshotsValues.map({ (arg: (id: String, info: [String : Any])) -> DINotification in
                let (id, info) = arg
                let notification = DINotification(id: id, dict: info)
                return notification
            })
            return notifications
        }
        return nil
    }

}
