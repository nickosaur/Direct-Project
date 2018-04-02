//
//  DIUpcomingNavigationController.swift
//  Direct
//
//  Created by Kesong Xie on 10/30/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIUpcomingNavigationController.swift
 *
 * This file is used as the overall container for the upcoming event feed view.
 * It will instantiate the view and perform any and all setup required after the
 * view has been loaded.
 */

import UIKit

class DIUpcomingNavigationController: DICoreNavigationController {
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: - StoryboardInstantiable
extension DIUpcomingNavigationController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DIUpcomingNavigationController {
        return DIApp.Storyboard.upcoming.instantiateViewController(withIdentifier: DIUpcomingNavigationController.className) as! DIUpcomingNavigationController
    }
}
