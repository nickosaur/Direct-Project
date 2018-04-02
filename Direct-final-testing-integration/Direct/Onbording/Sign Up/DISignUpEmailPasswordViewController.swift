//
//  DISignUpEmailPasswordViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/11/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

class DISignUpEmailPasswordViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            self.scrollView.alwaysBounceVertical = true
        }
    }
    @IBOutlet weak var emailTextField: UITextField!  {
        didSet {
            self.emailTextField.delegate = self
            self.emailTextField.clearButtonMode = .whileEditing
            self.emailTextField.autocorrectionType = .no
            self.emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            
        }
    }
    @IBOutlet weak var passwordTextField: UITextField!  {
        didSet {
            self.passwordTextField.delegate = self
            self.passwordTextField.clearButtonMode = .whileEditing
            self.passwordTextField.isSecureTextEntry = true
            self.passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var signUpBtn: UIButton! {
        didSet {
            self.updateSignupBtnState()
            self.signUpBtn.becomeRoundedButton()
        }
    }
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!  {
        didSet {
            self.activityIndicatorView.activityIndicatorViewStyle = .white
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    @IBAction func signupBtnTapped(_ sender: UIButton) {
        self.signupInfo?.email = self.emailTextField.text ?? ""
        self.signupInfo?.password = self.passwordTextField.text ?? ""
        sender.isUserInteractionEnabled = false
        sender.setTitle(nil, for: .normal)
        self.activityIndicatorView.startAnimating()
        guard let info = self.signupInfo else {
            return
        }

        DIAuth.signUp(withInfo: info) { (user) in
            // push a preference picker view controller
            if user != nil {
                self.navigationController?.pushViewController(self.categoryPicker, animated: true)
            } else {
                let popup = Popup()
                popup.displayPopup(title: "Invalid sign up credential", description: "Please try again", buttonTitle: "Ok", view: self)
                self.activityIndicatorView.stopAnimating()
                sender.isUserInteractionEnabled = true
                sender.setTitle("Sign Up", for: .normal)
            }
        }
    }
    
    lazy var categoryPicker: DICategoriesPickerViewController = {
        let categoryPicker = DICategoriesPickerViewController.instantiateFromInstoryboard()
        categoryPicker.hideCloseButton = true
        categoryPicker.delegate = self
        categoryPicker.pickerTitle = "What interests you most"
        categoryPicker.doneBtnTitle = "Finish"
        return categoryPicker
    }()
    
    var signupInfo: DISignUpInfo?
    
    // keyboard state
    var adjustOffsetDiff: CGFloat = 0
    var keyboardPresented: Bool = false
    var editingTextField: UITextField?

    
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }categiry
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
    
    
    @objc func keyboardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset.y -= self.adjustOffsetDiff
        })
    }
    
    
    func updateSignupBtnState() {
        if let email = self.emailTextField.text,
           let password = self.passwordTextField.text,
           !email.isEmpty,
           !password.isEmpty {
            self.signUpBtn.isUserInteractionEnabled = true
            self.signUpBtn.alpha = 1
        } else {
            self.signUpBtn.isUserInteractionEnabled = false
            self.signUpBtn.alpha = 0.8
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.updateSignupBtnState()
    }
    
    func showHome() {
        let tabBarVC = DITabBarViewController.instantiateFromInstoryboard()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.pushViewController(tabBarVC, animated: true)
    }
}

extension DISignUpEmailPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.editingTextField = textField
        return true
    }
    
    func textFieldWillReturn(textField: UITextField) {
        self.editingTextField = nil
    }
}


extension DISignUpEmailPasswordViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.view.endEditing(true)
    }
}

extension DISignUpEmailPasswordViewController: DICategoriesPickerViewControllerdelegate {
    func didFinishSelectingCategories(viewController: DICategoriesPickerViewController, categories: [String]) {
        // save the categories for a given user
        let currentUser =  DIAuth.auth.current
        currentUser?.setEventPreferencesString(categories: categories)
        currentUser?.sync(completionHandler: { (user) in
            if user != nil {
                // save finished
                if DIApp.userDefault.bool(forKey: DIApp.onboardingVisitedKey) {
                    // present home
                    self.showHome()
                } else {
                    let introductionNVC = DIIntroductionNavigationController.instantiateFromInstoryboard()
                    introductionNVC.interactivePopGestureRecognizer?.isEnabled = false
                    viewController.present(introductionNVC, animated: true, completion: nil)
                    // save a flag to the default indicating that  the user has already viewed the onboarding screens
                    DIApp.userDefault.set(true, forKey: DIApp.onboardingVisitedKey)
                }
            }
        })
    }
}
