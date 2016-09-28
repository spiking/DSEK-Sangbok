//
//  GlobalFunctions.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import MBProgressHUD
import Firebase
import AHKActionSheet

func isUserAuthenticated() {
    DataService.ds.REF_USERS.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
        
        if snapshot.hasChild(userID()) {
            print("Authenticated!")
        } else {
            print("Not Authenticated!")
        }
    }
}

func dateSincePosted(_ timestamp: String) -> String {
    let dateCreated = Date(timeIntervalSince1970: Double(timestamp)!)
    let dateDiff = Date().offsetFrom(dateCreated)
    
    return dateDiff
}

func detectPhoneModel() {
    if UIDevice().userInterfaceIdiom == .phone {
        switch UIScreen.main.nativeBounds.height {
        case 480:
            print("iPhone Classic")
        case 960:
            print("iPhone 4 or 4S")
            iPhoneType = "4"
        case 1136:
            print("iPhone 5 or 5S or 5C")
            iPhoneType = "5"
        case 1334:
            print("iPhone 6 or 6S or 7")
            iPhoneType = "6"
        case 2208:
            print("iPhone 6+ or 6S+ or 7+")
            iPhoneType = "6+"
        default:
            print("Unknown")
        }
    }
}

func setupMenu(_ actionSheet: AHKActionSheet) {
    actionSheet.blurTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    actionSheet.blurRadius = 8.0
    
    if iPhoneType == "4" || iPhoneType == "5" {
        actionSheet.buttonHeight = 50.0
        actionSheet.cancelButtonHeight = 70
    } else {
        actionSheet.buttonHeight = 60.0
        actionSheet.cancelButtonHeight = 80
    }
    
    actionSheet.cancelButtonHeight = 80
    actionSheet.animationDuration = 0.5
    actionSheet.cancelButtonShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    // Seperator not working in iOS 10 yet
    actionSheet.separatorColor = UIColor(red: 30, green: 30, blue: 30, alpha: 0.2)
    actionSheet.selectedBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
    let font = UIFont(name: "Avenir", size: 17)
    actionSheet.buttonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.white]
    actionSheet.disabledButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.gray]
    actionSheet.destructiveButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.red]
    actionSheet.cancelButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.white]
}

func userID() -> String {
    if let uid = UserDefaults.standard.value(forKey: KEY_UID) as? String {
        return uid
    } else {
        return " "
    }
}

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func showFavoriteAlert(_ favorite: Bool, view: UIView) {
    hud = MBProgressHUD.showAdded(to: view, animated: true)
    hud.mode = MBProgressHUDMode.customView
    
    var image: UIImage
    
    if favorite {
        image = UIImage(named: "Checkmark")!
        hud.labelText = "SPARAD"
    } else {
        image = UIImage(named: "DeleteNew")!
        hud.labelText = "BORTTAGEN"
    }
    
    hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
    hud.customView = UIImageView(image: image)
    hud.hide(true, afterDelay: 1.5)
}
