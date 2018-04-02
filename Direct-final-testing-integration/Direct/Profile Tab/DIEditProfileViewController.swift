//
//  DIEditProfileViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/18/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit
import GooglePlaces
import GooglePlacePicker
import GoogleMaps

protocol DIEditProfileViewControllerDelegate: class {
    func didFinishUpdatingProfile(currentUser: DIUser?)
}

class DIEditProfileViewController: UIViewController {

    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var displayNameTextField: UITextField! {
        didSet {
            self.displayNameTextField.delegate = self
        }
    }
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!  {
        didSet {
            self.activityIndicatorView.activityIndicatorViewStyle = .white
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    @IBOutlet weak var introductionTextViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var preferEventCategoriesTextField: UITextField! {
        didSet {
            self.preferEventCategoriesTextField.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(categoryTextFieldTapped))
            self.preferEventCategoriesTextField.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var defaultLocationTextField: UITextField! {
        didSet {
            // tap to present location picker
            self.defaultLocationTextField.delegate = self
            let tap = UITapGestureRecognizer(target: self, action: #selector(locationLabelTapped(_:)))
            self.defaultLocationTextField.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            self.profileImageView.becomeCircleView()
            self.profileImageView.backgroundColor = DIApp.Style.Color.grayColor
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(presentPhotoPicker))
            self.profileImageView.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var introductionTextView: UITextView! {
        didSet {
            self.introductionTextView.delegate = self
            self.introductionTextView.textContainerInset = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        }
    }
    
    @IBOutlet weak var saveBtn: UIButton! {
        didSet {
            self.saveBtn.becomeRoundedButton()
        }
    }
    
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.setTitle("", for: .normal)
        self.activityIndicatorView.startAnimating()
        guard let fullname = self.displayNameTextField.text, !fullname.isEmpty else {
            objectAssertionFailure(withMessage: "fullname can't be nil")
            return
        }
        
        let introduction = self.introductionTextView.text ?? ""
        let categorieString = self.preferEventCategoriesTextField.text ?? ""
        DIUser.updateProfile(fullname: fullname, introduction: introduction, preferredCategory: categorieString, profileImageData: self.profilePictureImageData, defaultLocation: self.defaultLocation) { (user) in
            if user != nil {
                self.delegate?.didFinishUpdatingProfile(currentUser: user)
            } else {
                self.delegate?.didFinishUpdatingProfile(currentUser: nil)
            }
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func changeProfilePictureBtnTapped(_ sender: UIButton) {
        let picker = DIPhotoPicker(presenter: self)
        picker.presentAddingOption(withTitle: nil)
    }
    
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    weak var delegate: DIEditProfileViewControllerDelegate?
    
    private var selectedCategories = [String]() {
        didSet {
            let selectedCategoriesString = self.selectedCategories.joined(separator: ", ")
            self.preferEventCategoriesTextField.text = selectedCategoriesString
        }
    }
    
    lazy var picker: DICategoriesPickerViewController = {
        let picker = DICategoriesPickerViewController.instantiateFromInstoryboard()
        picker.delegate = self
        picker.hideCloseButton = false
        picker.selectedCategories = self.selectedCategories
        picker.pickerTitle = "What interests you most"
        picker.doneBtnTitle = "Finish"
        return picker
    }()
    
    // keyboard state
    private var editingTextField: UITextField?
    private var adjustOffsetDiff: CGFloat = 0
    private var keyboardPresented: Bool = false
    
    var profilePictureImageData: Data?
    var defaultLocation: DILocation? {
        didSet {
            self.defaultLocationTextField.text = self.defaultLocation?.name
        }
    }
    
    lazy var placePicker: GMSPlacePickerViewController = {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        return placePicker
    }()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let currentUser = DIAuth.auth.current else {
            return
        }
        if let profileURL = currentUser.profileImageURL {
            self.profileImageView.loadImage(fromURL: profileURL)
        }
        self.selectedCategories = Array(currentUser.eventPreferencesCategoryList)
        self.displayNameTextField.text = currentUser.fullname
        self.introductionTextView.text = currentUser.bio
        // dynamic sizing textview
        let size = self.introductionTextView.sizeThatFits(CGSize(width: self.introductionTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        self.introductionTextViewHeightConstraint.constant = size.height
        self.introductionTextView.isScrollEnabled = false
        
        // config the place picker
        GMSPlacesClient.provideAPIKey(DIApp.GMSPlacesClientAPIKey)
        GMSServices.provideAPIKey(DIApp.GMSServicesAPIKey)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func presentPhotoPicker() {
        let picker = DIPhotoPicker(presenter: self)
        picker.presentAddingOption(withTitle: nil)
    }
    
    @objc private func categoryTextFieldTapped() {
        DispatchQueue.main.async {
            self.picker.selectedCategories = self.selectedCategories
            self.present(self.picker, animated: true, completion: nil)
        }
    }
    
    @objc func locationLabelTapped(_ gesture: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.present(self.placePicker, animated: true, completion: nil)
        }
    }
}

// MARK: - StoryboardInstantiable
extension DIEditProfileViewController: StoryboardInstantiable {
    static func instantiateFromInstoryboard() -> DIEditProfileViewController{
        return DIApp.Storyboard.profile.instantiateViewController(withIdentifier: DIEditProfileViewController.className) as! DIEditProfileViewController
    }
}

// MARK: - UITextFieldDelegate
extension DIEditProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension DIEditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        self.introductionTextViewHeightConstraint.constant = size.height
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - ImagePickerControllerPresenter
extension DIEditProfileViewController: ImagePickerControllerPresenter {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
                    self.profileImageView.image = image
                    self.profilePictureImageData = UIImageJPEGRepresentation(image, 0.8)
                }
            }
        }
    }
}

// MARK: - DICategoriesPickerViewControllerdelegate
extension DIEditProfileViewController: DICategoriesPickerViewControllerdelegate {
    func didFinishSelectingCategories(viewController: DICategoriesPickerViewController, categories: [String]) {
        self.selectedCategories = categories
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - GMSPlacePickerViewControllerDelegate
extension DIEditProfileViewController: GMSPlacePickerViewControllerDelegate {
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        let clLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        self.defaultLocation = DILocation(name: place.name, cllocation: clLocation)
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
