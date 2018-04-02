//
//  DINotificationTableViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 11/4/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DINotificationTableViewCell.swift
 *
 * This file defines the appearance for a notification cell in the notification tab. In Direct,
 * a user may receive notifications for events which they have expressed interest in (by
 * RSVP’ing to the event), or to events which match their selected interest categories.
 */

import UIKit

class DINotificationTableViewCell: UITableViewCell {
    // event title
    @IBOutlet weak var titleLabel: UILabel!
    // event location
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    
    // image given with notification
    @IBOutlet weak var thumbnailImageView: UIImageView! {
        didSet {
            self.thumbnailImageView.layer.cornerRadius = DIApp.Style.thumbnailCornerRaidus
            self.thumbnailImageView.clipsToBounds = true
            self.thumbnailImageView.contentMode = .scaleAspectFill
            self.thumbnailImageView.backgroundColor = DIApp.Style.Color.imagePlaceholderGray
        }
    }
    
    // responding to notification
    @IBOutlet weak var respondActionButton: UIButton!
    
    // reason user received this notification
    @IBOutlet weak var notificationTypeLabel: UILabel!
    
    // set the fields of notification
    var notification: DINotification? {
        didSet {
            if let url = URL(string: self.notification?.event?.coverPath ?? "") {
                self.thumbnailImageView.loadImage(fromURL: url)
            }
            self.notificationTypeLabel.text = self.notification?.notificationTypeLabel
            self.titleLabel.text = self.notification?.event?.title
            self.locationLabel.text = self.notification?.event?.location?.name
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
