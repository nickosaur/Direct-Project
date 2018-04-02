//
//  AppDelegate.swift
//  Direct
//
//  Created by Xie kesong on 10/18/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* AppDelegate.swift
 *
 * This file is used as the overall manager for all the app components. It links
 * several key aspects of the app (the database, location, and notification
 * features) with the core program.
 */

import UIKit
import Firebase
import CoreLocation
import UserNotifications

@objc protocol DIAppStateDelegate: class {
    @objc optional func didRegisteredNotification()
    @objc optional func didFailRegisteredNotification()
    @objc optional func applicationWillResignActive()
    @objc optional func applicationDidBecomeActive()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    weak var appStateDelegate: DIAppStateDelegate?
    
    let locationManager = CLLocationManager()
    
    /* application
     *
     * This function configures firebase and location services if possible, and will
     * launch the application with the allowed settings.
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        // cloud messaging
        Messaging.messaging().delegate = self
        
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name:"AvenirNext-Medium", size:10)!], for: .normal)
        self.setWindowTintColor()

        if DIApp.userDefault.bool(forKey: DIApp.onboardingVisitedKey) {
            // once the user has ready being shown the onboarding step
            // save the current user location to the database
            let center =  UNUserNotificationCenter.current()
            center.delegate = self as? UNUserNotificationCenterDelegate
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                // Enable or disable features based on authorization
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
       
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        self.appStateDelegate?.applicationWillResignActive?()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // the App just enters foreground, save the user location to database for nearby event fetching
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.appStateDelegate?.applicationDidBecomeActive?()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /* application
     *
     * This function is used for when the user has enabled notifications from the
     * application.
     */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.appStateDelegate?.didRegisteredNotification?()
        Messaging.messaging().apnsToken = deviceToken
        DIDeviceToken.setDeviceToken(completionBlock: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.appStateDelegate?.didFailRegisteredNotification?()
    }

    /* application
     *
     * This function is used to retrieve event information and create a notification
     * about that event for a user.
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let info = userInfo as? [String: Any]{
            guard let eventKey = info["eventKey"] as? String else {
                return
            }
            // fetch the event information
            DIEvent.fetchEvent(withKey: eventKey, completionBlock: { (event) in
                if let event = event {
                    DINotification.addNotification(forEvent: event, completionBlock: nil)
                    
                    // should present the event detail when notification is tapped
                    let info: [String: Any] = [
                        DIApp.DINotification.OpenEventDetailFromRemoteNotification.eventInfoKey: event
                    ]
                    let notification = Notification(name: DIApp.DINotification.OpenEventDetailFromRemoteNotification.name, object: self, userInfo: info)
                    NotificationCenter.default.post(notification)
                    completionHandler(.newData)
                } else {
                    completionHandler(.failed)
                }
            })
        } else {
            completionHandler(.failed)
        }
    }
    
    /* setWindowTintColor
     *
     * This function is used to set the visual style of the window tint.
     */
    private func setWindowTintColor(){
        self.window?.backgroundColor = UIColor.white
        self.window?.tintColor = DIApp.Style.Color.themeBlue
    }

}

extension AppDelegate: MessagingDelegate {
    /* messaging
     *
     * This function is used to set the token of the device receiving a notification.
     */
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Just refresh the fcmToken" + fcmToken)
        DIDeviceToken.setDeviceToken(completionBlock: nil)
    }
    
}


