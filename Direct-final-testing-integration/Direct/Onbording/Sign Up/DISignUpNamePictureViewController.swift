//
//  DISignUpNamePictureViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/10/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

fileprivate let adjustOffset: CGFloat = 20.0

class DISignUpNamePictureViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!  {
        didSet {
            self.scrollView.alwaysBounceVertical = true
        }
    }
    @IBOutlet weak var cameraIconImageView: UIImageView!
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
    @IBOutlet weak var displayNameTextField: UITextField! {
        didSet {
            self.displayNameTextField.clearButtonMode = .whileEditing
            self.displayNameTextField.autocorrectionType = .no
            self.displayNameTextField.autocapitalizationType = .words
            self.displayNameTextField.delegate = self
            self.displayNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        }
    }
    
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var nextBtn: UIButton! {
        didSet {
            self.updateNextBtnState()
            self.nextBtn.becomeRoundedButton()
        }
    }
    
    @IBAction func nextBtnTapped(_ sender: UIButton) {
        self.signupInfo?.fullname = self.displayNameTextField.text ?? ""
        self.performSegue(withIdentifier: DISignUpEmailPasswordViewController.className, sender: self)
    }
    // keyboard state
    var adjustOffsetDiff: CGFloat = 0
    var keyboardPresented: Bool = false
    
    var signupInfo: DISignUpInfo?
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: Notification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    
    @objc func keyboardDidShow(notification: Notification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            //make sure the textfield origin is refer to the global view
            let origin = self.displayNameTextField.convert(self.displayNameTextField.frame.origin, to: nil)
            let keyboardOriginY = keyboardFrame.origin.y
            let textFieldOriginY = origin.y
            let textFieldHeight = self.displayNameTextField.frame.size.height
            let adjustOffsetDiff = textFieldOriginY + textFieldHeight - keyboardOriginY
            guard  adjustOffsetDiff > 0  else{
                return
            }
            self.adjustOffsetDiff = adjustOffsetDiff + adjustOffset
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.contentOffset.y = self.scrollView.contentOffset.y + self.adjustOffsetDiff
            })
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset.y -= self.adjustOffsetDiff
        })
    }
    
    
    func updateNextBtnState() {
        if let text = displayNameTextField.text, !text.isEmpty {
            self.nextBtn.isUserInteractionEnabled = true
            self.nextBtn.alpha = 1
        } else {
            self.nextBtn.isUserInteractionEnabled = false
            self.nextBtn.alpha = 0.8
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == self.displayNameTextField {
            self.updateNextBtnState()
        }
    }
    
    @objc func presentPhotoPicker() {
        self.cameraIconImageView.animateBounceView()
        let picker = DIPhotoPicker(presenter: self)
        picker.presentAddingOption(withTitle: nil)
    }
    
    
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let iden = segue.identifier, iden == DISignUpEmailPasswordViewController.className{
            if let emailPasswordVC = segue.destination as? DISignUpEmailPasswordViewController {
                emailPasswordVC.signupInfo = signupInfo
            }
        }
    }
}

extension DISignUpNamePictureViewController: ImagePickerControllerPresenter {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
                    self.cameraIconImageView.isHidden = true
                    self.profileImageView.image = image
                    self.signupInfo?.profilePictureImageData = UIImageJPEGRepresentation(image, 0.8)
                }
            }
        }
    }
}

extension DISignUpNamePictureViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


extension DISignUpNamePictureViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.view.endEditing(true)
    }
}
