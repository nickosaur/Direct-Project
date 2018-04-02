//
//  DISignUpOrganizerSelectionViewController.swift
//  Direct
//
//  Created by Kesong Xie on 11/10/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

class DISignUpOrganizerSelectionViewController: UIViewController {
    
    var signupInfo = DISignUpInfo()
    
    @IBOutlet weak var backBtn: UIButton!
    
    @IBOutlet weak var yesBtn: UIButton! {
        didSet {
            self.yesBtn.becomeRoundedButton()
        }
    }
    
    @IBAction func yesBtnTapped(_ sender: UIButton) {
        self.signupInfo.isOrganizer = true
        self.performSegue(withIdentifier: DISignUpNamePictureViewController.className, sender: self)
    }
    
    
    @IBAction func noBtnTapped(_ sender: UIButton) {
        self.signupInfo.isOrganizer = false
        self.performSegue(withIdentifier: DISignUpNamePictureViewController.className, sender: self)
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        sender.animateBounceView()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let iden = segue.identifier, iden == DISignUpNamePictureViewController.className{
            if let nameProfilePicVC = segue.destination as? DISignUpNamePictureViewController {
                nameProfilePicVC.signupInfo = signupInfo
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
