//
//  DILocationManager.swift
//  Direct
//
//  Created by Kesong Xie on 11/7/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventManager.swift
 *
 * This file is used as a buffer for obtaining the location. It will request
 * permission to access the user's location before attempting to retrieve
 * said location, and then if it is allowed access it will return the
 * location information.
 */

import CoreLocation

class DILocationManager{
    /* getCurrentLocation
     *
     * This function is used to request permission to access a user's location.
     * If access is given, it will return said location. Else, returns nil.
     */
    class func getCurrentLocation() -> CLLocation? {
        let locManager = CLLocationManager()
        return CLLocation(latitude: 32.8787741, longitude: -117.23756119999997)
    }
}
