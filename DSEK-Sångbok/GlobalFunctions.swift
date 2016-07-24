//
//  GlobalFunctions.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation

func dateSincePosted(timestamp: String) -> String {
    let dateCreated = NSDate(timeIntervalSince1970: Double(timestamp)!)
    let dateDiff = NSDate().offsetFrom(dateCreated)
    
    return dateDiff
}

func checkiPhoneType() {
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
        print(uid)
        return uid
    } else {
        return ""
    }
}