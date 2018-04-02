//
//  DIApp.swift
//  Direct
//
//  Created by Kesong Xie on 10/19/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIApp.swift
 *
 * This file is used as the overall wrapper for the layout of the app. It initializes
 * storyboards for all the tabs which are to be displayed along the bottom tab of
 * the application, and it sets the style of the components.
 */

import UIKit

struct DIApp {
    // set view parameters
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let thumbnailImageMaxDimension: CGFloat = 600;
    static let thumbnailImageCompressionQuality: CGFloat = 0.8;
    
    // define categories offered as user options
    static let supportedCategories = ["Music", "Sports", "Food", "Community", "Arts", "Movies", "Science", "Fashion", "Education", "Business"]

    static let userDefault = UserDefaults()
    static let GMSPlacesClientAPIKey = "AIzaSyDWgrglpRDRqRVwPJMo-SkTq5xg7kJS0hk"
    static let GMSServicesAPIKey = "AIzaSyDW25T3aCOsksT-brSC1dKEzxhc9oxv1u4"
    static let onboardingVisitedKey = "onboardingVisited"

    // all possible main screen pages
    struct Storyboard{
        static let main = UIStoryboard(name: "Main", bundle: nil)
        static let Onboarding = UIStoryboard(name: "Onboarding", bundle: nil)
        static let home = UIStoryboard(name: "Home", bundle: nil)
        static let upcoming = UIStoryboard(name: "Upcoming", bundle: nil)
        static let search = UIStoryboard(name: "Search", bundle: nil)
        static let notification =  UIStoryboard(name: "Notification", bundle: nil)
        static let profile =  UIStoryboard(name: "Profile", bundle: nil)
    }
    
    // if app was opened via a notification, then open that event
    struct DINotification{
        struct OpenEventDetailFromRemoteNotification {
            static let name = Notification.Name(rawValue: "AppOpenedFromRemoteNotification")
            static let eventInfoKey = "event"
        }
        struct AccountSignOut {
            static let name = Notification.Name(rawValue: "AccountSignOut")
        }
        struct UpcomingUIShouldRefresh {
            static let name = Notification.Name(rawValue: "UpcomingUIShouldRefresh")
        }
    }
    
    // set colors/themes/style for each component
    struct Style{
        static let fontName = "AvenirNext"
        static let thumbnailCornerRaidus: CGFloat = 6.0
        struct Color {
            static let grayColor = UIColor(hexString: "#D6D5D5")
            static let deactiveColor = UIColor(hexString: "#D9D9D9")
            static let themeBlue = UIColor(hexString: "#0076BA")
            static let bodyFontColor = UIColor(hexString: "#5E5E5E")
            static let upcomingYellow = UIColor(hexString: "#F8BA00")
            static let liveRed = UIColor(hexString: "#EE220C")
            static let endedGray = UIColor(hexString: "#929292")
            static let imagePlaceholderGray = grayColor
        }
        struct NavigationBar{
            static let barTintColor = UIColor.white
            static let isTranslucent = false
        }
        
        struct TabBar{
            static let tintColor = UIColor(red: 0, green: 118 / 255.0, blue: 186 / 255.0, alpha: 1)
            static let barTintColor = UIColor.white
            static let isTranslucent = false
        }
    }
}
