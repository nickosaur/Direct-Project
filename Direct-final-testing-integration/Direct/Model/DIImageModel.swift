//
//  DIImageModel.swift
//  Direct
//
//  Created by Kesong Xie on 10/20/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIImageModel.swift
 *
 * This file is used to relate images with urls which can be stored in the firebase
 * data storage. It will deal with adding and removing images from the database.
 */

import Foundation
import FirebaseStorage

fileprivate let photoDir = "photo/"
fileprivate let supportPhotoType = ".png"

class DIImageModel: NSObject, DISyncObjectProtocol {
    var fetchedURL: URL?
    var imageData: Data?
    //use the tempHash for removal and filename for upload
    var tempHash: String?
    var fetchURLString: String? {
        return self.fetchedURL?.absoluteString
    }
    
    /* init
     *
     * This function is used to initialize an object by the image URL.
     */
    convenience init(fetchedURL: URL?) {
        self.init()
        self.fetchedURL = fetchedURL
    }
    
    /* init
     *
     * This function is used to initialize a new object based on the image data
     */
    convenience init(imageData: Data) {
        self.init()
        self.imageData = imageData
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
     * This function is used to sync the status of an image with the database, either
     * by adding an object to storage if it meats the requirements for supported
     * images, or by deleting an object from storage.
     */
    func sync(option: DISyncOption = .add, completionBlock: ((DIImageModel) -> Void)?) {
        switch option{
        case .add:
            guard var filename = self.tempHash else {
                self.objectAssertionFailure(withMessage: "temp hash is nil")
                return
            }
            filename += supportPhotoType
            guard let imageData = self.imageData else {
                self.objectAssertionFailure(withMessage: "image data is nil")
                return
            }
            let storageRef = Storage.storage().reference().child(photoDir + filename)
            storageRef.putData(imageData, metadata: nil) { (storageMetaData, error) in
                if let storageMetaData = storageMetaData {
                    self.fetchedURL = storageMetaData.downloadURL()
                }
                completionBlock?(self)
            }
        case .delete:
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

