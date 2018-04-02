//
//  DIGeoFire.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIGeoFire.swift
 *
 * This file is used to link the program with the GeoFire library, allowing for the
 * app to integrate location queries. In this manner, users of Direct can find nearby
 * events to attend based on their current location. In addition, the application will
 * allow users to post content about the event by comparing the event with the
 * user’s current location. Users can also add events and choose from any location
 * defined in Google Maps, rather than having to define an address.
 */

import GeoFire
import FirebaseDatabase

fileprivate let eventStartDateRoot = "event_start_date_fetch"

class DIGeoFire: DIBaseModel {
    
    /* eventReference
     *
     * This function returns a reference to the location of an event.
     */
    class func eventReference(eventStartDateUTCString: String) -> GeoFire {
        return GeoFire(firebaseRef: DatabaseReference.child(eventStartDateRoot + "/" + eventStartDateUTCString + "/event_loc/"))
    }
    
    /* userReference
     *
     *This function returns a reference to a user’s current location.
     */
    class func userReference() -> GeoFire {
        return GeoFire(firebaseRef: DatabaseReference.child("user_loc/"))
    }
}
