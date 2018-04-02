//
//  DisplayPopup.swift
//  Direct
//
//  Created by Vicky Tang on 11/29/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

import Foundation
import PopupDialog

class Popup {
    func popupAppearance(){
        //Message, Popup Body
        let dialogAppearance = PopupDialogDefaultView.appearance()
        
        //dialogAppearance.backgroundColor      = UIColor.white
        dialogAppearance.titleFont = UIFont(name: "AvenirNext-Bold", size: 18)!
        dialogAppearance.messageFont = UIFont(name: "AvenirNext-medium", size: 14)!
        
        //Container
        let pcv = PopupDialogContainerView.appearance()
        pcv.cornerRadius = 14
        
        //Button
        let cb = CancelButton.appearance()
        cb.titleFont      = UIFont(name: "AvenirNext-Bold", size: 17)!
        cb.titleColor     = DIApp.Style.Color.themeBlue
        cb.buttonColor    = UIColor.white
        cb.separatorColor = DIApp.Style.Color.grayColor
    }
    
    func displayPopup(title: String, description: String, buttonTitle: String, view: UIViewController){
        popupAppearance()
        
        let popup = PopupDialog(title: title, message: description, image: nil)
        let buttonOne = CancelButton(title: buttonTitle, action: nil)
        popup.addButtons([buttonOne])
        
        view.present(popup, animated: true, completion: nil)
    }
}
