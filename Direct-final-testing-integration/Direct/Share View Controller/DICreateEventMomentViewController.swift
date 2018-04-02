//
//  DICreateEventMomentViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DICreateEventMomentViewController.swift
 *
 * This file is used to handle any user input related to creating an “Event Moment”
 * in the Direct app. The definition of creating an “Event Moment” is to add a new
 * photo or video to the event details page of an event which is currently live
 * (the event is happening or has finished recently). The content uploaded by the
 * user will then be available to be viewed by other users of the app who are
 * interested in that event. This file delegates to another class to create the “Event
 * Moment”, namely DIEventManager.swift
 */

import UIKit
import AVFoundation

@objc protocol DICreateEventMomentViewControllerDelegate  {
    @objc optional func didFinishAddingEventMoment(moment: DIMoment?)
}


class DICreateEventMomentViewController: UIViewController {
    // so user may scroll
    @IBOutlet weak var scrollView: UIScrollView!
    
    // recognizes if user presses on the blank image, indicating they wish to add one
    @IBOutlet weak var playerView: DIPlayerView! {
        didSet {
            self.playerView.clipsToBounds = true
            self.playerView.contentMode = .scaleAspectFill
            self.playerView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(presentPhotoPicker))
            self.playerView.addGestureRecognizer(tap)
        }
    }
    
    // any caption the user wants to associate with their new content
    @IBOutlet weak var captionTextField: UITextField! {
        didSet {
            self.captionTextField.clearButtonMode = .whileEditing
            self.captionTextField.delegate = self
        }
    }
    
    // view changes depending on user activity
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    private var editingTextField: UITextField?
    fileprivate var mediaURL: URL? // video uploading
    fileprivate var coverData: Data? // photo uploading
    fileprivate var hasVideoAttachment = false
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer!
    
    // keyboard state
    private var adjustOffsetDiff: CGFloat = 0
    private var keyboardPresented: Bool = false
    
    weak var delegate: DICreateEventMomentViewControllerDelegate?
    
    var event: DIEvent?

    /* shareBtnTapped
     *
     * This function will handle the event when a user presses the share button,
     * indicating that they wish to add a photo or video to the preexisting stream
     * of images from that event.
     */
    @IBAction func shareBtnTapped(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.setTitle(nil, for: .normal)
        self.activityIndicatorView.startAnimating()
        guard let event = self.event else {
            return
        }
        let caption = self.captionTextField.text ?? ""
        let eventManager = DIEventManager(event: event)
        if self.hasVideoAttachment && self.mediaURL != nil {
            guard let url = self.mediaURL else {
                return
            }
            eventManager.createEventMoment(mediaURL: url, isVideoAttachment: self.hasVideoAttachment, caption: caption) {
                moment in
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.didFinishAddingEventMoment?(moment: moment)
                    }
                }
            }
        } else if !self.hasVideoAttachment && self.coverData != nil{
            eventManager.createEventMoment(imageData: self.coverData!, isVideoAttachment: self.hasVideoAttachment, caption: caption) {
                moment in
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegate?.didFinishAddingEventMoment?(moment: moment)
                    }
                }
            }
        } else {
            sender.setTitle("Share", for: .normal)
            self.activityIndicatorView.stopAnimating()
            let popup = Popup()
            popup.displayPopup(title: "Please Add a Photo or Video", description: "Add photo or video to event", buttonTitle: "Ok", view: self)
        }
    }
    
    /* closeBtnTapped
     *
     * This function will handle the event when the user presses the close button,
     * indicating that they have completed the process of adding a photo/video.
     */
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        self.playerView.backgroundColor = DIApp.Style.Color.themeBlue
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
    
    /* presentPhotoPicker
     *
     * This function will delegate to DIPhotoPicker to allow the user to choose a
     * photo or video either from their preexisting photo library, or by directly using
     * their camera.
     */
    @objc func presentPhotoPicker() {
        let picker = DIPhotoPicker(presenter: self)
        picker.presentAddingOption(withTitle: "Select a photo or video for your moment")
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
        self.playerLayer.removeFromSuperlayer()
        self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.playerLayer.frame = self.playerView.bounds
        self.playerView.layer.addSublayer(self.playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        self.startPlayer()
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
    
    /* startPlayer
     *
     * This function is used to play a video from the beginning.
     */
    func startPlayer() {
        self.player?.play()
    }
    
    /* keyboardDidShow
     *
     * This function will allow the keyboard to show when the user is in the process of
     * editing one of the fields
     */
    @objc func keyboardDidShow(notification: Notification) {
        if let editingTextField = self.editingTextField {
            if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                //make sure the textfield origin is refer to the global view
                let origin = editingTextField.convert(editingTextField.frame.origin, to: nil)
                let keyboardOriginY = keyboardFrame.origin.y
                let textFieldOriginY = origin.y
                let textFieldHeight = editingTextField.frame.size.height
                let adjustOffsetDiff = textFieldOriginY + textFieldHeight - keyboardOriginY
                guard  adjustOffsetDiff > 0  else{
                    return
                }
                self.adjustOffsetDiff = adjustOffsetDiff
                UIView.animate(withDuration: 0.3, animations: {
                    self.scrollView.contentOffset.y = self.scrollView.contentOffset.y + self.adjustOffsetDiff
                })
            }
        }
    }
    
    /* keyboardWillHide
     *
     * This function will hide the keyboard after the user no longer needs it (they are
     * scrolling away from the prompt)
     */
    @objc func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset.y -= self.adjustOffsetDiff
        })
    }
}


extension DICreateEventMomentViewController: ImagePickerControllerPresenter {
    /* imagePickerController
     *
     * This function is used when the user has finished uploading image/video content,
     * determining if it was a photo or video and then saving the content so that it may
     * later be displayed or played accordingly for other users.
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                if let videoURL = info["UIImagePickerControllerMediaURL"] as? URL {
                    // preview the video or image
                    self.configVideoLayer(withURL: videoURL)
                    self.mediaURL = videoURL
                    self.hasVideoAttachment = true
                } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    self.playerView.image = image
                    self.coverData = UIImageJPEGRepresentation(image, 0.8)
                    self.hasVideoAttachment = false
                }
            }
        }
    }
}

extension DICreateEventMomentViewController: UITextFieldDelegate {
    /* textFieldShouldReturn
     *
     * This function is used for handing when the user presses return, in which case
     * the keyboard should be dismissed.
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /* textFieldShouldBeginEditing
     *
     * This function is used when the user presses a field to edit, in which case the
     * keyboard will need to be displayed and none of the fields should be updated
     * in the event until the user is done editing.
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.editingTextField = textField
        return true
    }
    
    /* textFieldWillReturn
     *
     * This function is used to indicate that the user has completed editing a field so
     * that the keyboard can be hidden and information can be updated in the local
     * variables.
     */
    func textFieldWillReturn(textField: UITextField) {
        self.editingTextField = nil
    }
}

// MARK: - StoryboardInstantiable
extension DICreateEventMomentViewController: StoryboardInstantiable {
    /* instantiateFromInStoryBoard
     *
     * This function is used to load the view of the storyboard.
     */
    static func instantiateFromInstoryboard() -> DICreateEventMomentViewController {
        return DIApp.Storyboard.main.instantiateViewController(withIdentifier: DICreateEventMomentViewController.className) as! DICreateEventMomentViewController
    }
}


