//
//  DIPhotoPicker.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIPhotoPicker.swift
 *
 * This file is used to provide the ability for a user to upload a photo to the app.
 * The user will have the option to upload either preexisting content, via the
 * “Choose from Library” option, or to upload new content, via the “Using Camera”
 * option. This class also allows for removal of preexisting media or cancellation
 * of the selection process.
 */

import UIKit
import MobileCoreServices

// actions which the user may perform
fileprivate struct ActionTitle{
    static let library = "Choose from Library"
    static let camera = "Using Camera"
    static let cancel = "Cancel"
    static let remove = "Remove Current Photo"
}

// options to be presented to user
fileprivate struct AlertMessage{
    static let addCoverNew = "Add a Cover for New Item"
    static let newAdd = "Add Photo for an Item"
}

fileprivate let supportMediaType = "public.image"

class DIPhotoPicker{
    var presenter : ImagePickerControllerPresenter?
    
    required init(presenter: ImagePickerControllerPresenter){
        self.presenter = presenter
        
    }
    
    /* open
     *
     * This is used to open a selected image. There are constraints on what kind of
     * content will be allowed (i.e. needs to be in supported media format).
     */
    fileprivate func open(sourceType: UIImagePickerControllerSourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            if let availabeMediaType = UIImagePickerController.availableMediaTypes(for: sourceType),
                availabeMediaType.contains(supportMediaType)
            {
                let imagePickerVC = UIImagePickerController()
                imagePickerVC.delegate = presenter
                imagePickerVC.allowsEditing = true
                imagePickerVC.sourceType = sourceType
                imagePickerVC.videoMaximumDuration = 20
                imagePickerVC.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
                DispatchQueue.main.async {
                    (self.presenter as? UIViewController)?.present(imagePickerVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    /* openCamera
     *
     * This function is called to open the user’s camera.
     */
    func openCamera(){
        self.open(sourceType: .camera)
    }
    
    /* openLibrary
     *
     * This function is called to open the user’s photo library.
     */
    func openLibrary(){
        self.open(sourceType: .photoLibrary)
    }
    
    /* presentAddingOption
     *
     * This function is used to present the user with choices on where they wish
     * to upload content from (either library or camera roll).
     */
    func presentAddingOption(withTitle messageTitle: String? = nil){
        let cameraAction = UIAlertAction(title: ActionTitle.camera, style: .default) { (_) in
            self.openCamera()
        }
        let libraryAction = UIAlertAction(title: ActionTitle.library, style: .default) { (_) in
            self.openLibrary()
        }
        let actions = [cameraAction, libraryAction]
        self.present(style: .actionSheet,  title: messageTitle, withActions: actions)
    }
    
    /* presentDeleteOption
     *
     * This function is used to present the user with the choice to delete the image
     * they had previously selected.
     */
    func presentDeleteOption(forImageModel imageModel: DIImageModel){
        let removeAction = UIAlertAction(title: ActionTitle.remove, style: .default) { (_) in
            self.presenter?.removeAction?(forImageModel: imageModel)
        }
        let actions = [removeAction]
        self.present(style: .actionSheet, withActions: actions)
    }
    
    /* present
     *
     *  This function is used to present the user with an alert view controller.
     */
    fileprivate func present(style: UIAlertControllerStyle, title: String? = nil, message: String? = nil, withActions actions: [UIAlertAction], hasCancelAction: Bool = true) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: style)
        var mutableActions = actions
        if hasCancelAction {
            let cancelAction = UIAlertAction(title: ActionTitle.cancel, style: .cancel){ _ in
                self.presenter?.cancelAction?()
            }
            mutableActions.append(cancelAction)
        }
        for action in mutableActions{
            alertVC.addAction(action)
        }
        DispatchQueue.main.async {
            (self.presenter as? UIViewController)?.present(alertVC, animated: true, completion: nil)
        }
    }
}

