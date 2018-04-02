//
//  DILandingViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/31/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DILandingViewController.swift
 *
 * This file is used as the overall container for the page to be displayed when the
 * application is first opened. If the user is logged in, this will be the home screen.
 * Otherwise, it will have the user log in a preexisting account/sign up for a new
 * account. It will instantiate the view and perform any and all setup required after the
 * view has been loaded.
 */

import UIKit

class DILandingViewController: UIViewController {
    // placeholder before creating correct views
    @IBOutlet weak var placeholderContainerView: UIView! {
        didSet {
            self.placeholderContainerView.isHidden = true
        }
    }
    
    // home screen view
    @IBOutlet weak var homeContainerView: UIView! {
        didSet {
            self.homeContainerView.isHidden = true
        }
    }
    
    // welcome page view
    @IBOutlet weak var onboardingView: UIView! {
        didSet {
            self.onboardingView.isHidden = true
        }
    }
    
    var tabBarVC: DITabBarViewController?
    var onboardingNVC: DIOnboardingNavigationController?
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidSignOut(_:)), name: DIApp.DINotification.AccountSignOut.name, object: nil)
        if let currentAuthUser = DIAuth.shareFirebaseAuth.currentUser {
            self.placeholderContainerView.isHidden = false
            // fetch the user by id
            DIUser.fetchUser(withKey: currentAuthUser.uid, completionBlock: { (user) in
                DIAuth.auth.current = user
                self.showHome()
            })
        } else {
            self.showOnboarding()
        }
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
    
    /* showHome
     *
     * This function will display the home screen view of the application.
     */
    func showHome() {
        // load tab bar vc
        self.onboardingNVC?.removeFromParentViewController()
        let tabBarVC = DITabBarViewController.instantiateFromInstoryboard()
        self.tabBarVC = tabBarVC
        self.addChildViewController(tabBarVC)
        tabBarVC.view.frame = self.homeContainerView.bounds
        self.homeContainerView.addSubview(tabBarVC.view)
        tabBarVC.didMove(toParentViewController: self)
        self.tabBarVC = tabBarVC
        self.view.bringSubview(toFront: self.homeContainerView)
        self.homeContainerView.isHidden = false
    }
    
    /* showOnboarding
     *
     * This function will show the welcome page of the application.
     */
    func showOnboarding() {
        // load tab bar vc
        self.tabBarVC?.removeFromParentViewController()
        let onboardingNVC = DIOnboardingNavigationController.instantiateFromInstoryboard()
        self.addChildViewController(onboardingNVC)
        onboardingNVC.view.frame = self.onboardingView.bounds
        self.onboardingView.addSubview(onboardingNVC.view)
        onboardingNVC.didMove(toParentViewController: self)
        self.view.bringSubview(toFront: self.onboardingView)
        self.onboardingView.isHidden = false
    }
    
    /* accountDidSignOut
     *
     * This function will show the welcome page if the user is signed out
     */
    @objc func accountDidSignOut(_ notification: Notification) {
        self.showOnboarding()
    }
   
}
