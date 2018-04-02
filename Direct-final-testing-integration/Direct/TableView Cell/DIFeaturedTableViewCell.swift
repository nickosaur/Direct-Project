//
//  DIFeaturedTableViewCell..swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIFeaturedTableViewCell.swift
 *
 * This file defines the appearance for an event on the live feed. In Direct, users are able to
 * view a feed of featured events, on which they can scroll and view key information
 * about events which may interest them. This information includes the title, any photo
 * or video the creator has associated with the event, some information about the relative
 * time of the event compared to the current time (i.e one day ago, happening now, etc.),
 * and the creator of the event.
 */

import UIKit
import AVFoundation

fileprivate let playerStatusKeyPath = "status"

class DIFeaturedTableViewCell: DIEventCell {
    // event title
    @IBOutlet weak var titleLabel: UILabel!
    // event location
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    
    // fit the photo/video to the screen
    @IBOutlet weak var playerView: DIPlayerView! {
        didSet {
            self.playerView.layer.cornerRadius = 6.0
            self.playerView.contentMode = .scaleAspectFill
            self.playerView.clipsToBounds = true
            self.playerView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(playerViewTapped(_:)))
            self.playerView.addGestureRecognizer(tap)
        }
    }
    // dot color indicates if event is upcoming, happening, or ended
    @IBOutlet weak var statusDotView: DIEventStatusDotView!
    // when event is in relation to current time
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            self.timeLabel.textColor = DIApp.Style.Color.bodyFontColor
        }
    }
    // layout constraint
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    // image should never be blank
    @IBOutlet weak var placeHolderImageView: UIImageView! {
        didSet {
            self.placeHolderImageView.backgroundColor = DIApp.Style.Color.grayColor
            self.placeHolderImageView.layer.cornerRadius = 4.0
            self.placeHolderImageView.contentMode = .scaleAspectFill
            self.placeHolderImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var videoIcon: UIImageView!
    @IBOutlet weak var muteIcon: UIImageView!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer!
    var hasVideo = false
    var pausedTime: CMTime? = kCMTimeZero
    
    // set the fields for an event
    override var event: DIEvent! {
        didSet {
            self.playerLayer?.removeFromSuperlayer()
            self.player = nil
            self.placeHolderImageView.image = nil
            
            self.titleLabel.text = self.event?.title
            self.locationLabel.text = self.event?.location?.name
            
            if let coverURL = URL(string: self.event?.coverPath ?? "") {
                self.placeHolderImageView.setImageWith(coverURL)
            }
            if let videoURL = self.event?.videoPath {
                self.hasVideo = true
                self.configVideoLayer(withURL: videoURL)
                self.startPlayer()
            } else {
                self.videoIcon.isHidden = true
                self.muteIcon.isHidden = true
            }
            self.timeLabel.text = ((self.event.isEneded) ? "Ended " : "") +  DITime.getEndTimePrettyFormat(endTime: self.event.endTimeStamp ?? 0)
            if self.event.isLive {
                self.statusDotView.setStyle(style: .live)
            } else {
                self.statusDotView.setStyle(style: .ended)
            }
        }
    }
    
    /* configVideoLayer
     *
     * This function is used to set up the video, which will be displayed automatically
     * for users who are viewing an event moment.
     */
    func configVideoLayer(withURL url: URL) {
        self.player = AVPlayer(url: url)
        self.player?.isMuted = true
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.playerView.layer.addSublayer(self.playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
    }
    
    /* playerItemDidReachEnd
     *
     * This is used to loop a video, by starting the video again when it has reached
     * the end.
     */
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
        if self.hasVideo {
            self.playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width - 2 * leadingConstraint.constant, height: self.bounds.size.width - 2 * leadingConstraint.constant)
        }
    }
    
    /* awakeFromNib
     *
     * This function guarantees that the view will have all outlet instance variables
     * set for the display.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        (UIApplication.shared.delegate as? AppDelegate)?.appStateDelegate = self
    }

    /* setSelected
     *
     * This function configures the view for the selected state
     */
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    /* playerViewTapped
     *
     * This function will change the status of the volume of a video. If the video was
     * muted previously, it will now have sound on, and vice versa.
     */
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
    
    /* startPlayer
     *
     * This function is used to play a video from the beginning.
     */
    func startPlayer() {
        self.player?.play()
    }
    
    override func prepareForReuse() {
        self.muteIcon.alpha = 1
        self.muteIcon.image = #imageLiteral(resourceName: "mute-icon")
    }
}

extension DIFeaturedTableViewCell: DIAppStateDelegate {
    func applicationWillResignActive() {
        // stop the player
        self.player?.pause()
        self.pausedTime = self.player?.currentTime()
    }
    func applicationDidBecomeActive() {
        self.startPlayer()
    }
    
}
