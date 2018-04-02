//
//  DIEventManager.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventManager.swift
 *
 * This file is used as the buffer between DIEvent and DICreateEventViewController/
 * DICreateEventMomentViewController. It has methods to create Events (which
 * are social occasions created by a user who wishes to share information with
 * other users of the app) and Event Moments (which are pieces of footage added
 * to an event’s information feed by a user who is currently attending the event).
 */

import CoreLocation

class DIEventManager {
    // hold the event
    private let event: DIEvent
    
    // initialiation requires an associated event
    init(event: DIEvent) {
        self.event = event
    }
    
    /* createEvent
     *
     * This is used to create an Event. It takes in parameters of an event, with will be the
     * user input information such as name, description, location, associated categories,
     * start time, end time, and associated media content, and creates a DIEvent with
     * the given information.
     */
    class func createEvent(imageData: Data? = nil, mediaURL: URL? = nil, title: String, descriptionText: String, location: DILocation, categories: [String], startDateStringUTC: String, startTime: TimeInterval, endTime: TimeInterval, isVideoAttachment: Bool, completionHandler callback: @escaping (DIEvent?) -> Void) {
        if isVideoAttachment && mediaURL != nil {
            DIMediaManager.saveVideo(assetURL: mediaURL!, completionHandler: { (videoModel) in
                guard let videoModel = videoModel else {
                    return
                }
                guard let videoPath = videoModel.fetchedURL?.absoluteString else {
                    return
                }
                guard let coverPath = videoModel.coverImageModel?.fetchedURL?.absoluteString else {
                    return
                }
                DIEvent.create(title: title, descriptionText: descriptionText, categories: categories, videoPath: videoPath, coverPath: coverPath, location: location, startDateStringUTC: startDateStringUTC, startTimeStamp: startTime, endTimeStamp: endTime) { event in
                    // save the location information to the database
                    callback(event)
                }
            })
        } else if !isVideoAttachment && imageData != nil {
            let imageModel = DIImageModel(imageData: imageData!)
            imageModel.sync(completionBlock: { (model) in
                // get the fetch url
                guard let coverPath = model.fetchedURL?.absoluteString else {
                    callback(nil)
                    return
                }
                DIEvent.create(title: title, descriptionText: descriptionText, categories: categories, coverPath: coverPath, location: location, startDateStringUTC: startDateStringUTC, startTimeStamp: startTime, endTimeStamp: endTime) { event in
                    // save the location information to the database
                    callback(event)
                }
            })
        }
    }
    
    /* createEventMoment
     *
     * This is used to create an Event Moment. It takes in parameters of an event, with
     * will be the user input content, and it will add this event to the associated DIEvent,
     * so that the captured event can be shared with other users viewing the event page.
     */
    func createEventMoment(imageData: Data? = nil, mediaURL: URL? = nil, isVideoAttachment: Bool = false, caption: String, completionHandler callback: @escaping (DIMoment?) -> Void) {
        if isVideoAttachment && mediaURL != nil {
            DIMediaManager.saveVideo(assetURL: mediaURL!, completionHandler: { (videoModel) in
                guard let videoModel = videoModel else {
                    return
                }
                guard let videoPath = videoModel.fetchedURL?.absoluteString else {
                    return
                }
                guard let coverPath = videoModel.coverImageModel?.fetchedURL?.absoluteString else {
                    return
                }
                self.event.shareMoment(caption: caption, videoPath: videoPath, coverPath: coverPath, completionHanlder: { (moment) in
                    callback(moment)
                })
            })
        } else if !isVideoAttachment && imageData != nil {
            let imageModel = DIImageModel(imageData: imageData!)
            imageModel.sync(completionBlock: { (model) in
                // get the fetch url
                guard let coverPath = model.fetchedURL?.absoluteString else {
                    callback(nil)
                    return
                }
                self.event.shareMoment(caption: caption, coverPath: coverPath, completionHanlder: { (moment) in
                    callback(moment)
                })
            })
        }
    }
}
