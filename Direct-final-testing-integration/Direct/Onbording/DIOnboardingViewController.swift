//
//  DIOnboardingViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/10/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIOnboardingViewController.swift
 *
 * This file is used to handle the user’s interaction with the Welcome tab of
 * the application. In Direct, you are initially presented with a screen welcoming
 * you to the application.
 */

import UIKit

class DIOnboardingViewController: UIViewController {
    // button pressed by user to proceed into notification
    @IBOutlet weak var letsGoBtn: UIButton! {
        didSet {
            self.letsGoBtn.becomeRoundedButton()
        }
    }
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    /* didReceiveMemoryWarning
     *
     * This function releases memory used by the view controller when there is a low
     * amount of available memory.
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

