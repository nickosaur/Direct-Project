//
//  DICreateEventViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/25/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DICreateEventViewController.swift
 *
 * This file is used to handle any user input related to creating an Event in the Direct
 * app. An Event is a social occasion which a user can create by specifying details
 * including a name, description, date, time, and associated image or video. The
 * event will then be available in the database for other users to view and potentially
 * express interest in. This file delegates to DIEventManager.swift for the actual
 * creation of the event.
 */

import UIKit
import GeoFire
import AVFoundation
import GooglePlaces
import GooglePlacePicker
import GoogleMaps


@objc protocol DICreateEventViewControllerDelegate  {
    @objc optional func didFinishAddingEvent(_ event: DIEvent?)
}

class DICreateEventViewController: UIViewController {
    // location of event
    private var pickedLocation: GMSPlace?
    private var eventCoordinates: CLLocationCoordinate2D?
    private var setPlayerView: Bool?
    // so user may scroll
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            self.scrollView.delegate = self
        }
    }
    
    // recognizes if user presses on the blank image, indicating they wish to add one
    @IBOutlet weak var playerView: DIPlayerView! {
        didSet {
            self.setPlayerView = true
            self.playerView.contentMode = .scaleAspectFill
            self.playerView.clipsToBounds = true
            self.playerView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(presentPhotoPicker))
            self.playerView.addGestureRecognizer(tap)
        }
    }
    
    /* closeBtnTapped
     *
     * This function will handle the event when the user presses the close button,
     * indicating that they no longer wish to create an event
     */
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // the name of the event
    @IBOutlet weak var titleTextField: UITextField! {
        didSet {
            self.titleTextField.clearButtonMode = .whileEditing
            self.titleTextField.delegate = self
        }
    }
    
    // description of the event
    @IBOutlet weak var descriptionTextField: UITextField!{
        didSet {
            self.descriptionTextField.clearButtonMode = .whileEditing
            self.descriptionTextField.delegate = self
        }
    }

    // where the event will take place
    @IBOutlet weak var locationTextField: UITextField!{
        didSet {
            self.locationTextField.delegate = self
            let tap = UITapGestureRecognizer(target: self, action: #selector(locationButtonTapped(_:)))
            self.locationTextField.addGestureRecognizer(tap)
        }
    }
    
    // string of all chosen “tags” for the event, i.e. “Food, Tech”
    @IBOutlet weak var categoryTextField: UITextField! {
        didSet {
            self.categoryTextField.delegate = self
            self.categoryTextField.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(categoryTextFieldTapped))
            self.categoryTextField.addGestureRecognizer(tap)
        }
    }
    
    // saves the start date/time selected by user
    @IBOutlet weak var startTimeTextField: UITextField! {
        didSet {
            self.startTimeTextField.delegate = self
            self.startTimeTextField.inputView = self.datePicker;
            self.startTimeTextField.text = self.dateFormatter.string(from: Date())
        }
    }
    
    // saves the end date/time selected by user
    @IBOutlet weak var endTimeTextField: UITextField!{
        didSet {
            self.endTimeTextField.delegate = self
            self.endTimeTextField.inputView = self.datePicker;
            self.endTimeTextField.text = self.dateFormatter.string(from: Date())
        }
    }
    
    // button to add event
    @IBOutlet weak var addBtn: UIButton! {
        didSet {
            self.addBtn.becomeRoundedButton()
        }
    }
    
    // animate based on user activity
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    /* addBtnTapped
     *
     * This function will handle the event when a user presses the add button,
     * indicating that they wish to create a new event
     */
    @IBAction func addBtnTapped(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.setTitle(nil, for: .normal)
        self.activityIndicatorView.startAnimating()
        
        if (self.mediaURL == nil && self.coverData == nil) || (titleTextField.text?.isEmpty)! ||
            (descriptionTextField.text?.isEmpty)! ||
            (locationTextField.text?.isEmpty)! ||
            (categoryTextField.text?.isEmpty)! ||
            (startTimeTextField.text?.isEmpty)! ||
            (endTimeTextField.text?.isEmpty)! ||
            self.setPlayerView == false {
            
            sender.isUserInteractionEnabled = true
            sender.setTitle("Add", for: .normal)
            self.activityIndicatorView.stopAnimating()
            
            let popup = Popup()
            popup.displayPopup(title: "Missing Fields", description: "Please fill in all fields before adding an event", buttonTitle: "Ok", view: self)
            
            return
        }
        
        self.cretaeEvent{
            event in
            DispatchQueue.main.async {
                sender.isUserInteractionEnabled = true
                self.dismiss(animated: true) {
                    self.delegate?.didFinishAddingEvent?(event)
                }
            }
        }
    }
    
    weak var delegate: DICreateEventViewControllerDelegate?
    // creates one string of all user selected tags to save as categoryTextField
    private var selectedCategories = [String]() {
        didSet {
            let selectedCategoriesString = self.selectedCategories.joined(separator: ", ")
            self.categoryTextField.text = selectedCategoriesString
        }
    }
    fileprivate var mediaURL: URL? // video uploading
    fileprivate var coverData: Data? // photo uploading
    fileprivate var isVideoAttachment = false
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer!
    private var editingTextField: UITextField?
    // keyboard state
    private var adjustOffsetDiff: CGFloat = 0
    private var keyboardPresented: Bool = false
    
    // Date
    private lazy var dateFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEEE, MMM d, yyyy  h:mm a"
        return format
    }()
    // satrt Date format
    private lazy var startShortFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "YYYY-MM-dd"
        return format
    }()
    
    // delegates to provide user with prompt to pick date/time of event
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.backgroundColor = UIColor.white
        datePicker.addTarget(self, action: #selector(datePickeredValueChanged(_:)), for: .valueChanged)
        return datePicker
    }()
    
    // delegates to provide user with prompt to pick location of event
    lazy var placePicker: GMSPlacePickerViewController = {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        return placePicker
    }()

    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        self.playerView.backgroundColor = DIApp.Style.Color.themeBlue
        GMSPlacesClient.provideAPIKey(DIApp.GMSPlacesClientAPIKey)
        GMSServices.provideAPIKey(DIApp.GMSServicesAPIKey)
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
        picker.presentAddingOption(withTitle: "Select a photo or video for event")
    }
    
    /* createEvent
     *
     * This function gathers all the user input fields and delegates to DIEventManager
     * to create an event with the given information.
     */
    private func cretaeEvent(completionHandler callback: @escaping (DIEvent?) -> Void) {
        if self.mediaURL == nil && self.coverData == nil {
            return
        }
        guard let title = self.titleTextField.text else {
            return
        }
        guard !title.isEmpty else {
            return
        }
        
        guard let descriptionText = self.descriptionTextField.text else {
            return
        }
        guard let name = self.locationTextField.text else {
            return
        }
        guard !name.isEmpty else {
            return
        }
        
        // start time
        guard let startTimeInputText = self.startTimeTextField.text else {
            return
        }
        
        guard let startDateStringUTC = localToUTC(date: startTimeInputText) else {
            return
        }
        
        var startTime: Double = 0
        
        
        if startTimeInputText.isEmpty {
            startTime = Date().timeIntervalSince1970
        } else {
            if let s = self.dateFormatter.date(from: startTimeInputText) {
                startTime = s.timeIntervalSince1970
            } else {
                return
            }
        }
        
        // end time
        guard let endTimeInputText = self.endTimeTextField.text else {
            return
        }
        guard !endTimeInputText.isEmpty else {
            return
        }
        guard let endTime = self.dateFormatter.date(from: endTimeInputText)?.timeIntervalSince1970 else {
            return
        }
        
        guard let coordinates = self.pickedLocation?.coordinate else {
            return
        }
        
        let location = DILocation(name: name, cllocation:  CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude) )
        
        if self.isVideoAttachment && self.mediaURL != nil {
            DIEventManager.createEvent(mediaURL: self.mediaURL!, title: title, descriptionText: descriptionText, location: location, categories: self.selectedCategories, startDateStringUTC: startDateStringUTC, startTime: startTime, endTime: endTime, isVideoAttachment: self.isVideoAttachment) {
                event in
                callback(event)
            }
        } else if !self.isVideoAttachment && self.coverData != nil{
            DIEventManager.createEvent(imageData: self.coverData!, title: title, descriptionText: descriptionText, location: location, categories: self.selectedCategories, startDateStringUTC: startDateStringUTC, startTime: startTime, endTime: endTime, isVideoAttachment: self.isVideoAttachment){
                event in
                callback(event)
            }
        } else {
            callback(nil)
        }
    }
    
    /* configVideoLayer
     *
     * This function is used to set up the video, which will be displayed automatically
     * for users who are viewing an event moment.
     */
    private func configVideoLayer(withURL url: URL) {
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
    private func startPlayer() {
        self.player?.play()
    }
    
    /* categoryTextFieldTapped
     *
     * This function will handle the event when the user presses on the category field
     * in the event creation prompt. It will provide the user with a list of predetermined
     * categories which the user will be able to select from to associate with their event.
     */
    @objc private func categoryTextFieldTapped() {
       let picker = DICategoriesPickerViewController.instantiateFromInstoryboard()
        picker.delegate = self
        picker.hideCloseButton = false
        picker.selectedCategories = self.selectedCategories
        DispatchQueue.main.async {
            self.present(picker, animated: true, completion: nil)
        }
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
    
    /* datePickeredValueChanged
     *
     * This is used when the user makes a change to either of the time fields of the event,
     * to make sure the variables are storing the most recent input from the user.
     */
    @objc func datePickeredValueChanged(_ control: UIControl) {
        if let picker = control as? UIDatePicker {
            let selectedDate = picker.date
            self.editingTextField?.text = self.dateFormatter.string(from: selectedDate)
        }
    }
    
    /* locationButtonTapped
     *
     * This function is used to handle the event when the user presses the location
     * icon. In this case, they should be presented with the Google Maps API to
     * select their desired location.
     */
    @objc func locationButtonTapped(_ gesture: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.present(self.placePicker, animated: true, completion: nil)
        }
    }
    
    
}

extension DICreateEventViewController: ImagePickerControllerPresenter {
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
                    self.isVideoAttachment = true
                } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    self.playerView.image = image
                    self.coverData = UIImageJPEGRepresentation(image, 0.8)
                    self.isVideoAttachment = false
                }
            }
        }
    }
}

extension DICreateEventViewController: UITextFieldDelegate {
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

extension DICreateEventViewController: DICategoriesPickerViewControllerdelegate {
    /* didFinishSelectingCategories
     *
     * This function will allow the selectedCategories variable to be updated when the
     * user has finished updating their desired categories.
     */
    func didFinishSelectingCategories(viewController: DICategoriesPickerViewController, categories: [String]) {
        self.selectedCategories = categories
        self.dismiss(animated: true, completion: nil)
    }
}

extension DICreateEventViewController: UIScrollViewDelegate {
    /* scrollViewDidEndDragging
     *
     * This function determines if the user reached the end of the page, in which case
     * we wish to hide the keyboard (since the user completed editing).
     */
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.view.endEditing(true)
    }
}

// MARK: - GMSPlacePickerViewControllerDelegate
extension DICreateEventViewController: GMSPlacePickerViewControllerDelegate {
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        // Dismiss the place picker, as it cannot dismiss itself.
        self.pickedLocation = place
        self.locationTextField.text = place.name
        self.eventCoordinates = place.coordinate
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
    }
}
