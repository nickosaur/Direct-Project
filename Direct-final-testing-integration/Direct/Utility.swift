//
//  Utility.swift
//  Direct
//
//  Created by Kesong Xie on 10/31/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIUtility.swift
 *
 * This file is used for helpful methods pertaining mainly to time/date.
 * It deals with formatting time into strings which relate the current time
 * as compared to a different date/time, as well as dealing with the
 * formatting of date strings. This is useful in the Direct app because when
 * displaying events, we would like to inform users of whether the event
 * is already happening, or if not, how much time it will happen.
 */

import UIKit
import CoreLocation

/* triggerFeedbackImpact
 *
 * This function is used to let the generator know that an impact occurred.
 */
func triggerFeedbackImpact() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}

/* ago
 *
 * This function will determine when a date/time is in relation to the current
 * moment, and it will return a string with the information related in the
 * smallest relevant units (i.e. will try seconds, then minutes, then hours, etc).
 */
func ago(fromDate date: Date) -> String{
    let ellapseTimeSeconds = Int(-date.timeIntervalSinceNow)
    var output: String = ""
    if ellapseTimeSeconds < 15{
        output = "now"
    }else if ellapseTimeSeconds < 60{
        if ellapseTimeSeconds > 1 {
            output = "\(ellapseTimeSeconds) seconds ago"
        } else {
            output = "\(ellapseTimeSeconds) second ago"
        }
    }else if ellapseTimeSeconds < 60 * 60{
        if ellapseTimeSeconds / 60 > 1 {
            output = "\(ellapseTimeSeconds / 60) minutes ago"
        } else {
            output = "\(ellapseTimeSeconds / 60) minute ago"
        }
    }else if ellapseTimeSeconds < 60  * 60 * 24{
        if ellapseTimeSeconds / 3600 > 1 {
            output = "\(ellapseTimeSeconds / 3600) hours ago"
        } else {
            output = "\(ellapseTimeSeconds / 3600) hour ago"
        }
    }else if ellapseTimeSeconds < 60 * 60 * 24 * 7{
        if ellapseTimeSeconds / (3600 * 24) > 1 {
            output = "\(ellapseTimeSeconds / (3600 * 24)) days ago"
        } else {
            output = "\(ellapseTimeSeconds / (3600 * 24)) day ago"
        }
    }else{
        if ellapseTimeSeconds / (3600 * 24 * 7) > 1 {
            output = "\(ellapseTimeSeconds / (3600 * 24 * 7)) weeks ago"
        } else {
            output = "\(ellapseTimeSeconds / (3600 * 24 * 7)) week ago"
        }
    }
    return output;
}

/* upcomingIn
 *
 * This function is used to generate the string that tells you how soon an event
 * will begin. It will return a string with the information related in the smallest
 * relevant units (i.e. will try seconds, then minutes, then hours, etc).
 */
func upcomingIn(toDate date: Date) -> String {
    let ellapseTimeSeconds = Int(date.timeIntervalSince1970 - Date().timeIntervalSince1970)
    var output: String = ""
    if ellapseTimeSeconds < 15{
        output = "now"
    }else if ellapseTimeSeconds < 60{
        if ellapseTimeSeconds > 1 {
            output = "\(ellapseTimeSeconds) seconds"
        } else {
            output = "\(ellapseTimeSeconds) second"
        }
    }else if ellapseTimeSeconds < 60 * 60{
        if ellapseTimeSeconds / 60 > 1 {
            output = "\(ellapseTimeSeconds / 60) minutes"
        } else {
            output = "\(ellapseTimeSeconds / 60) minute"
        }
    }else if ellapseTimeSeconds < 60  * 60 * 24{
        if ellapseTimeSeconds / 3600 > 1 {
            output = "\(ellapseTimeSeconds / 3600) hours"
        } else {
            output = "\(ellapseTimeSeconds / 3600) hour"
        }
    }else if ellapseTimeSeconds < 60 * 60 * 24 * 7{
        if ellapseTimeSeconds / (3600 * 24) > 1 {
            output = "\(ellapseTimeSeconds / (3600 * 24)) days"
        } else {
            output = "\(ellapseTimeSeconds / (3600 * 24)) day"
        }
    }else{
        if ellapseTimeSeconds / (3600 * 24 * 7) > 1 {
            output = "\(ellapseTimeSeconds / (3600 * 24 * 7)) weeks"
        } else {
            output = "\(ellapseTimeSeconds / (3600 * 24 * 7)) week"
        }
    }
    return output;
}

/* localToUTC
 *
 * This will convert the time of an event from local time to universal
 * time, and format the time accordingly, returning this formatted time.
 */
func localToUTC(date:String) -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE, MMM d, yyyy  h:mm a"
    dateFormatter.calendar = NSCalendar.current
    dateFormatter.timeZone = TimeZone.current
    
    guard let dt = dateFormatter.date(from: date) else {
        return nil
    }
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = "YYYY-MM-dd"
    return dateFormatter.string(from: dt)
}

/* getCurrentUTCDateString
 *
 * This function will return the current time in universal time, formatted according
 * to our expected specifications.
 */
func getCurrentUTCDateString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = "YYYY-MM-dd"
    return dateFormatter.string(from: Date())
}

/* DITime
 *
 * This class is used to get time information and to format it according to certain
 * standards which are used consistently through our files.
 */
class DITime {
    /* getDay
     *
     * This is used to return a string for the date.
     */
    class func getDay(fromTimeInterval t: TimeInterval) -> String{
        let date = Date(timeIntervalSince1970: t)
        //[.day, .month, .year, .hour, .minute]
        let dateComponents = NSCalendar.current.dateComponents([.day], from: date)
        return String(dateComponents.day ?? 1)
    }
    
    /* getMonth
     *
     * This function is used to return a string for the month.
     */
    class func getMonth(fromTimeInterval t: TimeInterval) -> String{
        let date = Date(timeIntervalSince1970: t)
        //[.day, .month, .year, .hour, .minute]
        let dateComponents = NSCalendar.current.dateComponents([.month], from: date)
        return DITime.getMonthString(fromMonth: dateComponents.month ?? 0)
    }
    
    /* getMonthString
     *
     * This is used as a helper which returns the corresponding string for each month.
     */
    private class func getMonthString(fromMonth m: Int) -> String{
        switch m {
        case 1:
            return "JAN"
        case 2:
            return "FEB"
        case 3:
            return "MAR"
        case 4:
            return "APR"
        case 5:
            return "MAY"
        case 6:
            return "JUN"
        case 7:
            return "JUL"
        case 8:
            return "AUG"
        case 9:
            return "SEP"
        case 10:
            return "OCT"
        case 11:
            return "NOV"
        default:
            return "DEC"
        }
    }
    
    /* getEndTimePrettyFormat
     *
     * This will return the ending time of the event relative to the current time. This might
     * be an event which ended a certain amount of time ago, or something which will
     * end in a certain amount of time.
     */
    class func getEndTimePrettyFormat(endTime: TimeInterval) -> String{
        /* Date formatter to print date, time */
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        /* Current time to determine if the event has occured */
        let currentDate = Date()
        let endDate = Date(timeIntervalSince1970: endTime)
        let calendar = NSCalendar.current
        let isToday = calendar.isDateInToday(endDate)
        var end: String
        var isEnded = false
        //Start with ended if past date, ends if future
        if currentDate > endDate {
            end = ""
            isEnded = true
        }
        else {
            end = "Until "
        }
        
        //get time of day
        dateFormatter.setLocalizedDateFormatFromTemplate("hh:mm")
        let timeOfDay = dateFormatter.string(from: endDate)
        
        //check whether it was today or previous
        if(isToday) {
            if isEnded {
                return ago(fromDate: endDate)
            } else {
                return end + timeOfDay
            }
        }
            //not today, ex January 01
        else {
            if !isEnded {
                // live
                dateFormatter.setLocalizedDateFormatFromTemplate("MMM d")
                return end + dateFormatter.string(from: endDate) + ", " + timeOfDay
            } else {
                return end + ago(fromDate: endDate)
            }
        }
    }
}


