//
//  DITabBarViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/20/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DITabBarViewController.swift
 *
 * This file is used as the overall container for the tab bar display. It will call on the
 * corresponding instantiation for each of the options on the navigation bar along
 * the bottom of the screen in the application.
 */

import UIKit

class DITabBarViewController: UITabBarController {
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = DIApp.Style.TabBar.tintColor
        self.tabBar.barTintColor = DIApp.Style.TabBar.barTintColor
        
        // add tabs
        let homeNVC = HomeNavigationController.instantiateFromInstoryboard()
        let upcomingNVC = DIUpcomingNavigationController.instantiateFromInstoryboard()
        let profileNVC = DIProfileNavigationController.instantiateFromInstoryboard()
        let notificationNVC = DINotificationNavigationController.instantiateFromInstoryboard()
        self.viewControllers = [homeNVC, upcomingNVC, notificationNVC, profileNVC]
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


// MARK: - StoryboardInstantiable
extension DITabBarViewController: StoryboardInstantiable {
    /* instantiateFromInStoryBoard
     *
     * This function is used to load the view of the storyboard.
     */
    static func instantiateFromInstoryboard() -> DITabBarViewController{
        return DIApp.Storyboard.main.instantiateViewController(withIdentifier: DITabBarViewController.className) as! DITabBarViewController
    }
}
