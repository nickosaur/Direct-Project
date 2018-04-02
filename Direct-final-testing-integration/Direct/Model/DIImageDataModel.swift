//
//  DIImageDataModel.swift
//  Direct
//
//  Created by Kesong Xie on 10/20/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIImageDataModel.swift
 *
 * This file is used to deal with saved image data. It handles moving images
 * between the states of saved, fetched, and deleted, as need be.
 */

import Foundation

// possible states for an image
enum DIImageDataModelImageType {
    case unsaved
    case deleted
    case fetched
}

class DIImageDataModel: NSObject, DISyncObjectProtocol {
    lazy var unsavedImages = [DIImageModel]()
    lazy var deletedImages = [DIImageModel]()
    lazy var fetchedImages = [DIImageModel]()
    
    // the array of image models in sequences
    lazy var imageModels = [DIImageModel]()

    // total number of images
    var imageCount: Int {
        return self.imageModels.count
    }
    
    /* init
     *
     * This function is used to initialize a new object and store the fetched images.
     */
    init(withFetchedImages fetchedImages: [DIImageModel] ) {
        super.init()
        self.fetchedImages = fetchedImages
        self.imageModels += self.fetchedImages
    }
    
    /* init
     *
     * This function is used to initialize a new object.
     */
    override init() {
        super.init()
        //default init
    }
    
    /* addImageModel
     *
     * This function is used to create the model, while separating images by type
     * (i.e. whether they are deleted, fetched, or unsaved)
     */
    func addImageModel(model: DIImageModel, withType type: DIImageDataModelImageType) {
        switch type {
        case .deleted:
            self.deletedImages.append(model)
        case .fetched:
            self.fetchedImages.append(model)
            self.imageModels.append(model)
        case .unsaved:
            self.unsavedImages.append(model)
            self.imageModels.append(model)
        }
    }
    
    /* addToDeletedFromFetched
     *
     * This function is used to change the type of an image from fetched to deleted.
     */
    func addToDeletedFromFetched(forModel model: DIImageModel) {
        guard let index = self.fetchedImages.index(of: model) else{
            return
        }
        self.addImageModel(model: model, withType: .deleted)
        self.fetchedImages.remove(at: index)
    }
    
    /* removeUnsavedImages
     *
     * This image is used to remove an unsaved image.
     */
    func removeUnsavedImages(forModel model: DIImageModel) {
        guard let index = self.unsavedImages.index(of: model) else{
            return
        }
        self.unsavedImages.remove(at: index)
    }
    
    /* sync
     *
     * This function is used to sync the status of all images with the state of the image.
     */
    // MARK: - DISyncObjectProtocol
    func sync(option: DISyncOption = .add, completionBlock: ((DIImageDataModel) -> Void)?) {
        // delete all the images that need to be deleted
        let taskGroup = DispatchGroup()
        for imageToDelete in self.deletedImages {
            taskGroup.enter()
            imageToDelete.sync(option: .delete, completionBlock: { (_) in
                taskGroup.leave()
            })
        }
        
        // save all the unsavedImages
        DispatchQueue.global(qos: .userInitiated).async {
            // the final result should be move all the unsavedImages to the
            // fetchedImages
            for unsavedImage in self.unsavedImages {
                taskGroup.enter()
                unsavedImage.sync(completionBlock: { (_) in
                    taskGroup.leave()
                })
            }
            taskGroup.wait()
            DispatchQueue.main.async {
                // move all unsaved images to the fetched images
                self.fetchedImages  += self.unsavedImages
                self.unsavedImages = []
                completionBlock?(self)
            }
        }
    }    
}
