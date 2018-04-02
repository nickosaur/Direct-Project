//
//  DILocation.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DILocation.swift
 *
 * This file is used to handle location information. It stored coordinates, which can be used
 * to help with the location-based features of Direct (such as finding events nearby, allowing
 * users to check in only when they are in the vicinity of an event, etc.).
 */

import Foundation
import CoreLocation

// key information for firebase
fileprivate struct DILocationKey {
    static let root = "location"
    static let name = "name"
    static let cooridinate = "cooridinate"
    static let lat = "lat"
    static let long = "long"
}

class DILocation: DIBaseModel {
    // read location key and obtain stored latitude and longitude
    var coordinate: CLLocationCoordinate2D? {
        get {
            if let co = self.dict[DILocationKey.cooridinate] as? [String: CLLocationDegrees]{
                let lat = co[DILocationKey.lat]!
                let long = co[DILocationKey.long]!
                return CLLocationCoordinate2D(latitude: lat, longitude: long)
            }
            return nil
        }
        set(newValue){
            if var co = self.dict[DILocationKey.cooridinate] as? [String: Any]{
                co[DILocationKey.lat] = newValue?.latitude ?? 0
                co[DILocationKey.long] = newValue?.longitude ?? 0
            }
        }
    }
    
    // read the name from the key
    var name: String? {
        get {
            return self.dict[DILocationKey.name] as? String
        }
        set(newValue) {
            if let name = newValue {
                self.dict[DILocationKey.name] = name
            }
        }
    }
    
    // return coordinates for the current latitude and longitude
    lazy var dict = [String: Any]()
    var clLocation: CLLocation? {
        return CLLocation(latitude: self.coordinate?.latitude ?? 0, longitude: self.coordinate?.longitude ?? 0)
    }
    
    /* init
     *
     * This function is used to initialize a new object.
     */
    init(dict: [String: Any]) {
        super.init()
        self.dict = dict
    }
    
    /* init
     *
     * This function is used to initialize a new object with the given name and coordinate
     * information.
     */
    convenience init(name: String, cllocation: CLLocation) {
        let dict: [String: Any] = [
            DILocationKey.name: name,
            DILocationKey.cooridinate: [
                DILocationKey.lat: cllocation.coordinate.latitude,
                DILocationKey.long: cllocation.coordinate.longitude
            ]
        ]
        self.init(dict: dict)
    }
}
