//
//  DISettingsViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/18/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

protocol DISettingsViewControllerDelegate: class {
    func didFinishUpdatingSettings(currentUser: DIUser?)
}

class DISettingsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            self.scrollView.alwaysBounceVertical = true
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
    }
    
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!  {
        didSet {
            self.activityIndicatorView.activityIndicatorViewStyle = .white
            self.activityIndicatorView.hidesWhenStopped = true
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func logoutBtnTapped(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        DIAuth.signout {
            let notification = Notification(name: DIApp.DINotification.AccountSignOut.name)
            NotificationCenter.default.post(notification)
        }
    }
    
    weak var delegate: DISettingsViewControllerDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - StoryboardInstantiable
extension DISettingsViewController: StoryboardInstantiable {
    static func instantiateFromInstoryboard() -> DISettingsViewController{
        return DIApp.Storyboard.profile.instantiateViewController(withIdentifier: DISettingsViewController.className) as! DISettingsViewController
    }
}

