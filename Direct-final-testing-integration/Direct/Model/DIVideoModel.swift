//
//  DIVideoModel.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIVideoModel.swift
 *
 * This file is used to relate videos with urls which can be stored in the firebase
 * data storage. It will deal with adding and removing videos from the database.
 * In addition, it will store the url to a thumbnail image from the video, which will
 * be used as a cover image for the video in case the video is unable to load
 * immediately.
 */

import Foundation
import FirebaseStorage

fileprivate let videoDir = "video/"
fileprivate let supportPhotoType = ".mov"

class DIVideoModel: NSObject, DISyncObjectProtocol {
     // video URL
    var fetchedURL: URL?
    // cover thumbnail URL
    var fetchedCoverURL: URL? {
        return self.coverImageModel?.fetchedURL
    }
    var coverImageModel: DIImageModel?
    var data: Data?
    //use the tempHash for removal and filename for upload
    var tempHash: String?
    
    /* fetchURLString
     *
     * This function is used to retrieve the URL of an image as a string
     */
    var fetchURLString: String? {
        return self.fetchedURL?.absoluteString
    }
   
    /* init
     *
     * This function is used to initialize an object by the video URL.
     */
    convenience init(fetchedURL: URL?) {
        self.init()
        self.fetchedURL = fetchedURL
    }
    
    /* init
     *
     * This function is used to initialize a new object based on the video data
     */
    convenience init(data: Data, thumbnailData: Data) {
        self.init()
        self.data = data
        self.coverImageModel = DIImageModel(imageData: thumbnailData)
    }
    
    /* init
     *
     * This creates a hashcode for an image url.
     */
    private override init() {
        self.tempHash = UUID().uuidString
    }
    
    /* sync
     *
     * This function is used to sync the status of a video with the database, either
     * by adding an object to storage if it meats the requirements for supported
     * video type, or by deleting an object from storage (as well as any associated
     * content, such as the cover image).
     */
    func sync(option: DISyncOption = .add, completionBlock: ((DIVideoModel) -> Void)?) {
        // when sync the video to the firebase, save both the video and thumbnail
        switch option{
        case .add:
            let taskGroup = DispatchGroup()
            DispatchQueue.global(qos: .userInitiated).async {
                // save the video
                guard var filename = self.tempHash else {
                    self.objectAssertionFailure(withMessage: "temp hash is nil")
                    return
                }
                filename += supportPhotoType
                guard let data = self.data else {
                    self.objectAssertionFailure(withMessage: "image data is nil")
                    return
                }
                let storageRef = Storage.storage().reference().child(videoDir + filename)
                taskGroup.enter()
                storageRef.putData(data, metadata: nil) { (storageMetaData, error) in
                    if let storageMetaData = storageMetaData {
                        self.fetchedURL = storageMetaData.downloadURL()
                        taskGroup.leave()
                    }
                }
                //save the thumbnail
                taskGroup.enter()
                self.coverImageModel?.sync(completionBlock: { (imageModel) in
                    taskGroup.leave()
                })
                taskGroup.wait()
                DispatchQueue.main.async {
                    // move all unsaved images to the fetched images
                    completionBlock?(self)
                }
            }
            
        case .delete:
            // TODO: Need to clean up both the video file and thumbnail file
            guard let fetchedURLString = self.fetchURLString else {
                self.objectAssertionFailure(withMessage: "fetched url string is nil")
                return
            }
            let storageRef = Storage.storage().reference(forURL: fetchedURLString)
            storageRef.delete(completion: { (error) in
                completionBlock?(self)
            })
        }
    }
}

