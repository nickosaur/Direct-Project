//
//  DIUpcomingTableViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 10/30/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIUpcomingTableViewCell.swift
 *
 * This file defines the appearance an event cell in the  upcoming feed. In Direct, users can
 * view a feed of upcoming events, on which they can scroll and view key information
 * about events which may interest them. This information includes the title, any photo
 * or video the creator has associated with the event, the event date, and the location. The
 * user can then choose to RSVP to the event, which indicates that they are interested
 * in attending the event. They can also later cancel an RSVP if they no longer which to
 * attend.
 */

import UIKit

class DIUpcomingTableViewCell: DIEventCell {
    // scaled version of event image
    @IBOutlet weak var thumbnailImageView: UIImageView! {
        didSet {
            self.thumbnailImageView.layer.cornerRadius = DIApp.Style.thumbnailCornerRaidus
            self.thumbnailImageView.clipsToBounds = true
            self.thumbnailImageView.contentMode = .scaleAspectFill
            self.thumbnailImageView.backgroundColor = DIApp.Style.Color.grayColor
        }
    }
    // event title
    @IBOutlet weak var titleLabel: UILabel!
    // event location
    @IBOutlet weak var locationLabel: UILabel!
    // event date
    @IBOutlet weak var dayLabel: UILabel!
    // event month
    @IBOutlet weak var monthLabel: UILabel!
    // will change depending on if user is RSVP’d or not
    @IBOutlet weak var rsvpStatusIcon: UIImageView!
    // profile image of creator
    @IBOutlet weak var videoIconImageView: UIImageView!
    // number of users who have RSVP’d to this event
    @IBOutlet weak var rsvpCountLabel: UILabel!
    
    // define fields of an event
    override var event: DIEvent! {
        didSet {
            self.locationLabel.text = ""
            self.titleLabel.text = ""
            self.rsvpCountLabel.text = ""
            self.monthLabel.text = ""
            self.dayLabel.text = ""
            self.thumbnailImageView.image = nil
            
            if let coverURL = URL(string:  self.event.coverPath ?? "") {
                self.thumbnailImageView.loadImage(fromURL: coverURL)
            }
            self.titleLabel.text = self.event.title
            self.locationLabel.text = self.event.location?.name
            
            guard let currentUser = DIAuth.auth.current else {
                return
            }
            
            if currentUser.isUserRsvp(forEvent: self.event) {
                self.rsvpCountLabel.text = "You rsvped"
            } else if self.event.rsvpsUsers.count > 0 {
                self.rsvpCountLabel.text = "\(self.event.rsvpsUsers.count)" + "\(self.event.rsvpsUsers.count > 1 ? " people" : " person") rsvped"
            } else {
                self.rsvpCountLabel.text = "No rsvp yet"
            }
            
          
            // set rsvp status icon
            if currentUser.isUserRsvp(forEvent: self.event) {
                self.rsvpStatusIcon.image = #imageLiteral(resourceName: "checked-in-icon")
                self.rsvpStatusIcon.alpha = 1
            } else {
                self.rsvpStatusIcon.image = #imageLiteral(resourceName: "check-in-icon")
                self.rsvpStatusIcon.alpha = 0.6
            }
            
            guard let eventStartingTime = self.event.startTimeStamp else {
                return
            }
            self.monthLabel.text = DITime.getMonth(fromTimeInterval: eventStartingTime)
            self.dayLabel.text = DITime.getDay(fromTimeInterval: eventStartingTime)
        }
    }
    
    /* awakeFromNib
     *
     * This function guarantees that the view will have all outlet instance variables
     * set for the display.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    /* setSelected
     *
     * This function configures the view for the selected state
     */
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
