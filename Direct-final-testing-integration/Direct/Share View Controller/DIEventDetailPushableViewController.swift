//
//  DIEventDetailPushableViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/4/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventDetailPushableViewController.swift
 *
 * This file is used as the overall container for any event detail page view.
 * It will instantiate the view and perform any and all setup required after the
 * view has been loaded.
 */

import UIKit

class DIEventDetailPushableViewController: UIViewController {
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /* pushEventDetailVC
     *
     * This function is used to load and display the event details into the view.
     */
    func pushEventDetailVC(withEvent event: DIEvent) {
        let eventDetailVC = DIEventDetailiViewController.instantiateFromInstoryboard()
        eventDetailVC.event = event
        eventDetailVC.hidesBottomBarWhenPushed = true
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(eventDetailVC, animated: true)
        }
    }
}
