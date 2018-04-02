//
//  DIEventMomentTableViewCell.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventMomentTableViewCell
 *
 * This file defines the appearance for an event moment cell. In Direct, users are able to
 * post media content on the event page if the event is live (has already begun), and if the
 * user posting the content is within the vicinity of the event. Other users who then see this
 * event will be able to view these posted “event moments”.
 */

import UIKit
import AVFoundation

class DIEventMomentTableViewCell: UITableViewCell {
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
    
    // screen should never be blank
    @IBOutlet weak var placeHolderImageView: UIImageView! {
        didSet {
            self.placeHolderImageView.backgroundColor = DIApp.Style.Color.grayColor
            self.placeHolderImageView.contentMode = .scaleAspectFill
            self.placeHolderImageView.clipsToBounds = true
        }
    }
    
    // the username of the poster
    @IBOutlet weak var userFullnameLabel: UILabel!
    @IBOutlet weak var videoIcon: UIImageView!
    @IBOutlet weak var muteIcon: UIImageView!
    // caption for media content
    @IBOutlet weak var captionLabel: UILabel!
    // when media was posted
    @IBOutlet weak var createTimeLabel: UILabel!
    // display profile image of poster
    @IBOutlet weak var profilePicImageView: UIImageView! {
        didSet {
            self.profilePicImageView.contentMode = .scaleAspectFill
            self.profilePicImageView.layer.cornerRadius = self.profilePicImageView.frame.size.height / 2
            self.profilePicImageView.clipsToBounds = true
        }
    }
    
    var player: AVPlayer? {
        didSet {
            self.player?.isMuted = true
        }
    }
    var playerLayer: AVPlayerLayer!
  
    // define fields of the moment
    var moment: DIMoment! {
        didSet {
            self.playerLayer?.removeFromSuperlayer()
            self.player = nil
            self.placeHolderImageView.image = nil
            self.captionLabel.text = self.moment.caption
            self.createTimeLabel.text = ago(fromDate: self.moment.createdTime)
            
            if let coverURL = URL(string: self.moment.coverPath ?? "") {
                self.placeHolderImageView.setImageWith(coverURL)
            }
            if let videoURL = self.moment.videoPath {
                self.configVideoLayer(withURL: videoURL)
                self.startPlayer()
            } else {
                self.videoIcon.isHidden = true
                self.muteIcon.isHidden = true
            }
            
            // fetch the user
            if self.moment.user == nil {
                self.moment?.fetchUser(completionHandler: { (user) in
                    DispatchQueue.main.async {
                        if let url = user?.profileImageURL {
                            self.profilePicImageView.loadImage(fromURL: url)
                        }
                        self.userFullnameLabel.text = user?.fullname
                    }
                })
            } else {
                if let url = self.moment.user?.profileImageURL {
                    self.profilePicImageView.loadImage(fromURL: url)
                }
                self.userFullnameLabel.text = self.moment.user?.fullname
            }
            
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
    }

    /* setSelected
     *
     * This function configures the view for the selected state
     */
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /* configVideoLayer
     *
     * This function is used to set up the video, which will be displayed automatically
     * for users who are viewing an event moment.
     */
    func configVideoLayer(withURL url: URL) {
        self.player = AVPlayer(url: url)
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
        if self.moment.hasVideoAttachment {
            self.playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.width)
        }
    }
    
    /* startPlayer
     *
     * This function is used to play a video from the beginning.
     */
    func startPlayer() {
        self.player?.play()
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
    
}
