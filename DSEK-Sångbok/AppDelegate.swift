//
//  AppDelegate.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Auth
        
        FIRApp.configure()
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            
            let isAnonymous = user!.anonymous  // true
            let uid = user!.uid
            
            if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
                 print("Already signed up")
            } else {
                print("First login")
                NSUserDefaults.standardUserDefaults().setValue(uid, forKey: KEY_UID)
                DataService.ds.REF_USERS.child(uid).setValue(true)
    
            }
        }
        
        // Database
        
        let downloader = Downloader()
        downloader.toplistObserver()
        
        if realm.isEmpty {
            downloader.downloadSongsFromFirebase()
        }
        
        checkiPhoneModel()
        
        // Layout
        
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        ]
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
        return true
    }


    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

