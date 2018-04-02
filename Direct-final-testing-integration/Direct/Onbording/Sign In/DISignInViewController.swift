//
//  DISignInViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/21/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DINotificationViewController.swift
 *
 * This file is used to handle the user’s interaction with the Sign In screen
 * of the application. You can sign in to a preexisting account as long as it
 * has already been registered with the system with the email and password.
 * Planned functionality includes creating a password reset method in case a
 * user forgets their password.
 */

import UIKit
import PopupDialog

class DISignInViewController: UIViewController {
    // so the user may scroll
    @IBOutlet weak var scrollView: UIScrollView!  {
        didSet {
            self.scrollView.alwaysBounceVertical = true
        }
    }
    
    // button to sign in to preexisting account
    @IBOutlet weak var signInBtn: UIButton! {
        didSet {
            self.signInBtn.becomeRoundedButton()
        }
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    // button animates depending on user action
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!  {
        didSet {
            self.activityIndicatorView.activityIndicatorViewStyle = .white
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    /* signInBtnTapped
     *
     * This function is used to handle the event when the user presses the sign in
     * button. In this case, the user will enter email and password fields, and the
     * function will delegate to attempt to authenticate the user information. If the
     * login is successful the user will be redirected to the home tab of the application.
     * Otherwise, an error message will appear.
     */
    @IBAction func signInBtnTapped(_ sender: UIButton) {
        let email = self.emailTextField.text ?? ""
        let password = self.passwordTextField.text ?? ""
        sender.isUserInteractionEnabled = false
        sender.setTitle(nil, for: .normal)
        self.activityIndicatorView.startAnimating()
        DIAuth.signIn(email: email, password: password, completionHandler: { (user) in
            if user != nil {
                DIAuth.auth.current = user
                self.showHome()
            } else {
                let popup = Popup()
                popup.displayPopup(title: "Incorrect Email or Password", description: "Please try again", buttonTitle: "Ok", view: self)
                self.activityIndicatorView.stopAnimating()
                sender.isUserInteractionEnabled = true
                sender.setTitle("Sign In", for: .normal)
                print("incorrect password")
            }
        })
    }
    
    // for user input email
    @IBOutlet weak var emailTextField: UITextField!  {
        didSet {
            self.emailTextField.delegate = self
            self.emailTextField.clearButtonMode = .whileEditing
            self.emailTextField.autocorrectionType = .no
            self.emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    // for user input password
    @IBOutlet weak var passwordTextField: UITextField!   {
        didSet {
            self.passwordTextField.delegate = self
            self.passwordTextField.clearButtonMode = .whileEditing
            self.passwordTextField.isSecureTextEntry = true
            self.passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    @IBAction func forgotPasswordBtnTapped(_ sender: UIButton) {
    }
    
    // keyboard state
    var adjustOffsetDiff: CGFloat = 0
    var keyboardPresented: Bool = false
    var editingTextField: UITextField?
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateSignInBtnState()
    }

    /* keyboardDidShow
     *
     * This function will allow the keyboard to show when the user is in the process of
     * editing one of the fields.
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
    
    /* updateSignInBtnState
     *
     * This function is used to change the appearance of the button based on
     * whether the user is able to press on it or not.
     */
    func updateSignInBtnState() {
        if let email = self.emailTextField.text,
            let password = self.passwordTextField.text,
            !email.isEmpty,
            !password.isEmpty {
            self.signInBtn.isUserInteractionEnabled = true
            self.signInBtn.alpha = 1
        } else {
            self.signInBtn.isUserInteractionEnabled = false
            self.signInBtn.alpha = 0.8
        }
    }
    
    /* textFieldDidChange
     *
     * This function is used to update the state of the button after the user enters
     * input into the text field.
     */
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.updateSignInBtnState()
    }
    
    /* showHome
     *
     * This function is used to redirect to the home page screen after a successful
     * login by a user.
     */
    func showHome() {
        let tabBarVC = DITabBarViewController.instantiateFromInstoryboard()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.navigationController?.pushViewController(tabBarVC, animated: true)
    }

}

extension DISignInViewController: UITextFieldDelegate {
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
     * until the user is done editing.
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.editingTextField = textField
        return true
    }
    
    func textFieldWillReturn(textField: UITextField) {
        self.editingTextField = nil
    }
}
