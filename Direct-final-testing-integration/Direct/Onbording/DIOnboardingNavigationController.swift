//
//  DIOnboardingNavigationController.swift
//  Direct
//
//  Created by Kesong Xie on 11/14/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIOnboardingNavigationController.swift
 *
 * This file is used as the overall container for the initial navigation view.
 * It will instantiate the view and perform any and all setup required after the
 * view has been loaded. Initially, you are presented with a screen prompting
 * you to sign up/sign in, unless you are logged in already.
 */

import UIKit

class DIOnboardingNavigationController: DICoreNavigationController {
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    /* didReceiveMemoryWarning[
     *
     * This function releases memory used by the view controller when there is a low
     * amount of available memory.
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK:  - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - StoryboardInstantiable
extension DIOnboardingNavigationController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DIOnboardingNavigationController {
        return DIApp.Storyboard.Onboarding.instantiateViewController(withIdentifier: DIOnboardingNavigationController.className) as! DIOnboardingNavigationController
    }
}

