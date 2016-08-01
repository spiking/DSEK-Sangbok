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

func isUserAuthenticated() {
    DataService.ds.REF_USERS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
        
        if snapshot.hasChild(getUserID()) {
            print("Authenticated!")
        } else {
            print("Not Authenticated!")
        }
    }
}

func dateSincePosted(timestamp: String) -> String {
    let dateCreated = NSDate(timeIntervalSince1970: Double(timestamp)!)
    let dateDiff = NSDate().offsetFrom(dateCreated)
    
    return dateDiff
}

func checkiPhoneModel() {
    if UIDevice().userInterfaceIdiom == .Phone {
        switch UIScreen.mainScreen().nativeBounds.height {
        case 480:
            print("iPhone Classic")
        case 960:
            print("iPhone 4 or 4S")
            iPhoneType = "4"
        case 1136:
            print("iPhone 5 or 5S or 5C")
            iPhoneType = "5"
        case 1334:
            print("iPhone 6 or 6S")
            iPhoneType = "6"
        case 2208:
            print("iPhone 6+ or 6S+")
            iPhoneType = "6+"
        default:
            print("unknown")
        }
    }
}

func getUserID() -> String {
    if let uid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as? String {
        return uid
    } else {
        return ""
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func showFavoriteAlert(favorite: Bool, view: UIView) {
    hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
    hud.mode = MBProgressHUDMode.CustomView
    
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
    hud.hide(true, afterDelay: 1.0)
}