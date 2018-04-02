//
//  ImagePickerControllerPresenter.swift
//  Direct
//
//  Created by Xie kesong on 10/19/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* ImagePickerControllerPresenter.swift
 *
 * This file is used to provide a unified interface for the different
 * components of the project which involve picking media content. For
 * Direct, the main link is for creating events and for creating event
 * moments, both of which involve media content.
 */

import UIKit

@objc protocol ImagePickerControllerPresenter: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /** remove the target imageview
     */
    @objc optional func removeAction(forImageModel imageModel: DIImageModel)
    @objc optional func cancelAction()
}


