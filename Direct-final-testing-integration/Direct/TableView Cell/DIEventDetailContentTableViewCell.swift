//
//  DIEventDetailContentTableViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventDetailContentTableViewCell.swift
 *
 * This file defines the appearance for an event detail page. In Direct, a user is able to
 * see additional details about an event by navigating to the event detail page. On this
 * page, they can see media uploaded by the event creator, as well as view the written
 * description, some statistics on how many people have expressed interest in the
 * event, the location and time of the event, and who created the event.
 */

import UIKit
import AVFoundation


class DIEventDetailContentTableViewCell: UITableViewCell {
    // the name of the event
    @IBOutlet weak var titleLabel: UILabel!
    // the location of the event
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    
    // for the profile image view
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.becomeCircleView()
            self.profileImageView.backgroundColor = DIApp.Style.Color.grayColor
        }
    }
    
    @IBOutlet weak var videoIcon: UIImageView!
    @IBOutlet weak var muteIcon: UIImageView!
    // fit the photo/video to the screen
    @IBOutlet weak var playerView: DIPlayerView! {
        didSet {
            self.playerView.contentMode = .scaleAspectFill
            self.playerView.clipsToBounds = true
            self.playerView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(playerViewTapped(_:)))
            self.playerView.addGestureRecognizer(tap)
        }
    }
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    // screen should never be blank
    @IBOutlet weak var placeHolderImageView: UIImageView! {
        didSet {
            self.placeHolderImageView.backgroundColor = DIApp.Style.Color.grayColor
            self.placeHolderImageView.contentMode = .scaleAspectFill
            self.placeHolderImageView.clipsToBounds = true
        }
    }
    
    // link to creator’s profile
    @IBOutlet weak var userFullnameButton: UIButton!
    // the description for the event
    @IBOutlet weak var descriptionLabel: UILabel! {
        didSet {
            self.descriptionLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    
    @IBOutlet weak var organizerSymbolImageView: UIImageView!
    // when event was created
    @IBOutlet weak var createdTimeLabel: UILabel!
    
    
    var player: AVPlayer? {
        didSet {
            self.player?.isMuted = true
        }
    }
    var playerLayer: AVPlayerLayer!
    
    
    // respond count label displays checkin count if the event is live or ended
    // respond count label displays rsvp count if the event is upcoming
    @IBOutlet weak var respondCountLabel: UILabel! {
        didSet {
            self.respondCountLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    
    // set all the fields for the event
    var event: DIEvent! {
        didSet {
            guard let event = self.event else {
                return
            }
            
            self.playerLayer?.removeFromSuperlayer()
            self.player = nil
            self.placeHolderImageView.image = nil
            self.createdTimeLabel.text = "Created " + ago(fromDate: Date(timeIntervalSince1970: (self.event.createdTime ?? 0)))
            self.titleLabel.text = event.title
            self.locationLabel.text = event.location?.name
            self.userFullnameButton.setTitle(event.user?.fullname ?? "", for: .normal)
            self.organizerSymbolImageView.isHidden = !(event.user?.isOrganizer ?? false)
            self.descriptionLabel.text = event.descriptionText
            if event.isUpcoming {
                if event.rsvpsUsers.count > 0 {
                    self.respondCountLabel.text = "\(event.rsvpsUsers.count)" + "\(event.rsvpsUsers.count > 1 ? " people" : " person") rsvped"
                } else {
                     self.respondCountLabel.text = "Be the first one to rsvp"
                }
            } else {
                if event.visitedUsers.count > 0 {
                    self.respondCountLabel.text = "\(event.visitedUsers.count)" + "\(event.visitedUsers.count > 1 ? " people" : " person") checked in"
                } else {
                    self.respondCountLabel.text = "Be the first one to check in"
                }
            }
            
            if let coverURL = URL(string: event.coverPath ?? "") {
                self.placeHolderImageView.setImageWith(coverURL)
            }
            if let videoURL = event.videoPath {
                self.configVideoLayer(withURL: videoURL)
                self.startPlayer()
            } else {
                self.videoIcon.isHidden = true
                self.muteIcon.isHidden = true
            }
            
            if let url = self.event?.user?.profileImageURL {
                self.profileImageView.loadImage(fromURL: url)
            }
        }
    }
    
    
    
    // start playing video
    func configVideoLayer(withURL url: URL) {
        self.player = AVPlayer(url: url)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.playerView.layer.addSublayer(self.playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
    }
    
    // player item reach its end notifcation handler
    @objc func playerItemDidReachEnd(_ notification: NSNotification) {
        if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: kCMTimeZero)
            self.startPlayer()
        }
    }
    
    /* layoutSubviews
     *
     * This function sets the positioning of the subviews
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.event.isVideoEvent {
            self.playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.width)
        }
    }
    
    /* awakeFromNib
     *
     * This function guarantees that the view will have all outlet instance variables
     * set for the display.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
    
    // start player playing
    func startPlayer() {
        self.player?.play()
    }
    
    @objc func playerViewTapped(_ gesture: UITapGestureRecognizer) {
        if let player = self.player {
            player.isMuted = !player.isMuted
            if player.isMuted {
                self.muteIcon.alpha = 1
                self.muteIcon.image = #imageLiteral(resourceName: "mute-icon")
            } else {
                self.muteIcon.alpha = 1
                self.muteIcon.image = #imageLiteral(resourceName: "unmute-icon")
                UIView.animate(withDuration: 2.0, animations: {
                    self.muteIcon.alpha = 0
                })
            }
        }
    }
    
}
