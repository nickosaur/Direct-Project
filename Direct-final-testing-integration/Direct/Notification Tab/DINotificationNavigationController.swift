//
//  DINotificationNavigationController.swift
//  Direct
//
//  Created by Kesong Xie on 11/4/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DINotificationNavigationController.swift
 *
 * This file is used as the overall container for the notification screen view.
 * It will instantiate the view and perform any and all setup required after the
 * view has been loaded.
 */

import UIKit

class DINotificationNavigationController: DICoreNavigationController {
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

// MARK: - StoryboardInstantiable
extension DINotificationNavigationController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DINotificationNavigationController {
        return DIApp.Storyboard.notification.instantiateViewController(withIdentifier: DINotificationNavigationController.className) as! DINotificationNavigationController
    }
}

