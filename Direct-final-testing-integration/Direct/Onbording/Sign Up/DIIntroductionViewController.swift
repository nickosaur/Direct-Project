//
//  DIIntroductionViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/20/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import Firebase



class DIIntroductionViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet{
            self.scrollView.delegate = self
            self.scrollView.alwaysBounceVertical = false
            self.scrollView.showsVerticalScrollIndicator = false
            self.scrollView.showsHorizontalScrollIndicator = false
            self.scrollView.isPagingEnabled = true
        }
    }
    
    @IBOutlet weak var pageControl: UIPageControl!
    let locationManager = CLLocationManager()
    lazy var scenes = [DIOnboardingView]()
    var iaAskingNotificationPermission: Bool = false
    
    // save the current user location to the database
    
    override func viewDidLoad() {
        super.viewDidLoad()

        (UIApplication.shared.delegate as? AppDelegate)?.appStateDelegate = self
        let onboardLiveView = DIOnboardingView.instanceFromNib()
        onboardLiveView.backgroundImageView.image = #imageLiteral(resourceName: "onboard-live")
        onboardLiveView.actionBtn.setTitle("Enable location service", for: .normal)
        onboardLiveView.customDelegate = self
        onboardLiveView.option = .location
        
        let onboardNotificationView = DIOnboardingView.instanceFromNib()
        onboardNotificationView.backgroundImageView.image = #imageLiteral(resourceName: "onboard-notification")
        onboardNotificationView.actionBtn.setTitle("Allow push notification", for: .normal)
        onboardNotificationView.customDelegate = self
        onboardNotificationView.option = .notification

        scenes.append(onboardLiveView)
        scenes.append(onboardNotificationView)
        
        
        for (index, promptView) in self.scenes.enumerated() {
            promptView.frame = UIScreen.main.bounds
            promptView.frame.size.height = DIApp.screenHeight - 100
            promptView.frame.origin = CGPoint(x: CGFloat(index) * DIApp.screenWidth, y: 0)
            self.scrollView.addSubview(promptView)
        }
        
        self.pageControl.numberOfPages = self.scenes.count
        self.scrollView.contentSize = CGSize(width: DIApp.screenWidth * CGFloat(self.pageControl.numberOfPages), height: DIApp.screenHeight - 130)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK -: UIScrollViewDelegate
extension DIIntroductionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int(round(scrollView.contentOffset.x / DIApp.screenWidth))
        self.pageControl.currentPage = index
    }
}

// MARK -: OnboardingViewDelegate
extension DIIntroductionViewController: OnboardingViewDelegate {
    func onActionBtnTapped(_ option: DIOnboardingViewOption) {
        self.locationManager.delegate = self
        switch option {
        case .location:
            // asking for location permission
            self.locationManager.requestWhenInUseAuthorization()
        case .notification:
            // asking for notification permission
            let center =  UNUserNotificationCenter.current()
            center.delegate = self as? UNUserNotificationCenterDelegate
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                // Enable or disable features based on authorization
            }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func skipButtonTapped(_ option: DIOnboardingViewOption) {
        switch option {
        case .location:
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.contentOffset.x = DIApp.screenWidth
            })
        case .notification:
            self.showHome()
            
        }
    }
}


extension DIIntroductionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.locationManager.requestLocation()
            // scroll to next page
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.contentOffset.x = DIApp.screenWidth
            })
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentUserId = DIAuth.shareFirebaseAuth.currentUser?.uid else {
            return
        }
        if let location = locations.first {
            print("Found user's location: \(location)")
            // save the current user location
            DIGeoFire.userReference().setLocation(location, forKey: currentUserId)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func showHome() {
        (UIApplication.shared.delegate as? AppDelegate)?.appStateDelegate = nil
        let tabBarVC = DITabBarViewController.instantiateFromInstoryboard()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.pushViewController(tabBarVC, animated: true)
    }
}

// MARK: - StoryboardInstantiable
extension DIIntroductionViewController: StoryboardInstantiable {
    static func instantiateFromInstoryboard() -> DIIntroductionViewController {
        return DIApp.Storyboard.Onboarding.instantiateViewController(withIdentifier: DIIntroductionViewController.className) as! DIIntroductionViewController
    }
}

extension DIIntroductionViewController: DIAppStateDelegate {
    func didRegisteredNotification() {
        self.iaAskingNotificationPermission = true
    }
    
    func didFailRegisteredNotification() {
        self.iaAskingNotificationPermission = true
    }
    
    func applicationDidBecomeActive() {
        if self.iaAskingNotificationPermission {
            self.showHome()
        }
    }
}
