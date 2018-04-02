//
//  DIOnboardingView.swift
//  Direct
//
//  Created by Kesong Xie on 11/12/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import UIKit

protocol OnboardingViewDelegate: class {
    func onActionBtnTapped(_ option: DIOnboardingViewOption)
    func skipButtonTapped(_ option: DIOnboardingViewOption)
}

fileprivate let xibName = "DIOnboardingView"

enum DIOnboardingViewOption {
    case location
    case notification
}

class DIOnboardingView: UIView {
    
    weak var customDelegate: OnboardingViewDelegate?
    
    var option: DIOnboardingViewOption = .location
    
    @IBOutlet weak var backgroundImageView: UIImageView! {
        didSet {
            self.backgroundImageView.contentMode = .scaleAspectFit
            self.backgroundImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var actionBtn: UIButton! {
        didSet {
            self.actionBtn.becomeRoundedButton()
        }
    }
    
    
    @IBAction func skipBtnTapped(_ sender: UIButton) {
        self.customDelegate?.skipButtonTapped(self.option)
    }
    
    @IBAction func actionBtnTapped(_ sender: UIButton) {
        self.customDelegate?.onActionBtnTapped(self.option)
    }
    
    class func instanceFromNib() -> DIOnboardingView {
        let view = UINib(nibName: xibName, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DIOnboardingView
        return view
    }
    
}
