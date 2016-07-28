//
//  ViewController.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import PageMenu
import RealmSwift
import MBProgressHUD
import Firebase

class ViewController: UIViewController {
    
    var pageMenu : CAPSPageMenu!
    var downloadedSongs = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //        try! realm.write() {
        //            realm.deleteAll()
        //        }
        //
        
//        setupMenuButton()
        
        delay(3.0) {
            
            if songs.count == 0 {
                self.downloadSongsFromFirebase()
            } else {
                //                for song in songs {
                //                    let key : Int? = Int(song.key)
                //                    if key > 10 {
                //                        print("YES")
                //                        try! realm.write() {
                //                            realm.delete(song)
                //                        }
                //                    }
                //                }
            }
        }
    }
    
//    func setupMenuButton() {
//        let menuButton = UIButton(type: UIButtonType.Custom)
//        menuButton.setImage(UIImage(named: "List.png"), forState: UIControlState.Normal)
//        menuButton.addTarget(navigationController, action: #selector(NavigationController.showMenu), forControlEvents: UIControlEvents.TouchUpInside)
//        menuButton.frame = CGRectMake(0, 0, 20, 20)
//        let barButton = UIBarButtonItem(customView: menuButton)
//        self.navigationItem.leftBarButtonItem = barButton
//        
////        let icon = UIBarButtonItem(image: UIImage(named: "List.png"), style: .Plain, target: navigationController, action: #selector(NavigationController.showMenu))
////        icon.imageInsets = UIEdgeInsetsMake(-10, 0, 0, 0)
////        navigationItem.leftBarButtonItem = icon
//    }
//    
    
    func downloadNewSongs() {
        
        let urlString = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        let session = NSURLSession.sharedSession() // Singleton session object
        let url = NSURL(string: urlString)! // Creat url
        
        session.dataTaskWithURL(url) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if let responseData = data {
                
                do {
                    // Parse to the data to json
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments)
                    
                    if let dict = json as? Dictionary<String, AnyObject> {
                        
                        for (key, value) in dict {
                            
                            
                            
                            if let title = value["title"] as? String, let created = value["created"] as? String, let lyrics = value["lyrics"] as? String, let melodyTitle = value["melodyTitle"] as? String, let categoryTitle = value["categoryTitle"] as? String {
                                
                                let song = Song()
                                song._title = title
                                song._created = created
                                song._melodyTitle = melodyTitle
                                song._lyrics = lyrics
                                song._categoryTitle = categoryTitle
                                song._key = key
                                song._rating = 0
                                song._favorite = "FALSE"
                                
                                self.downloadedSongs.append(song)
                                
                            } else {
                                print("Did not found correct types!")
                            }
                        }
                        
                        self.saveToRealm()
                    }
                } catch {
                    print("Could not serialize!")
                }
            }
            }.resume()
    }
    
    
    func downloadSongsFromFirebase() {
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    if let songData = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let melodyTitle = songData["melody_title"] as? String, let categoryTitle = songData["category_title"] as? String, let rating = songData["rating"] as? Double {
                            
                            let song = Song()
                            
                            song._title = title
                            song._created = created
                            song._melodyTitle = melodyTitle
                            song._lyrics = lyrics
                            song._categoryTitle = categoryTitle
                            song._rating = rating
                            song._key = key
                            song._favorite = "FALSE"
                            
                            self.downloadedSongs.append(song)
                            
                        } else {
                            print(songData["title"])
                        }
                    }
                }
                self.saveToRealm()
            }
        }
    }
    
    
    func saveToRealm() {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            let realm = try! Realm()
            try! realm.write() {
                for song in self.downloadedSongs {
                    // No duplicates, check primary key
                    realm.add(song, update: true)
                }
            }
            
             NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        }
    }
    
    func sortSongs() {
        //        songs.sort({ $0.title > $1.title })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // MARK: - UI Setup
        
//        self.title = "D-SEK SÅNGBOK"
//        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
//        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
//        self.navigationController?.navigationBar.tintColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)]
        
        
        
        //        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "<-", style: UIBarButtonItemStyle.Done, target: self, action: "didTapGoToLeft")
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "->", style: UIBarButtonItemStyle.Done, target: self, action: "didTapGoToRight")
        
        // MARK: - Scroll menu setup
        
        // Initialize view controllers to display and place in array
        var controllerArray : [UIViewController] = []
        
        var controller2 : AllSongsVC = AllSongsVC(nibName: "AllSongsVC", bundle: nil)
        controller2.title = "SÅNGER"
        controller2.parentNavigationController = self.navigationController
        controllerArray.append(controller2)
        
        let controller3 : FavoritesVC = FavoritesVC(nibName: "FavoritesVC", bundle: nil)
        controller3.title = "FAVORITER"
        controller3.parentNavigationController = self.navigationController
        controllerArray.append(controller3)
        
        //        let controller5 : ToplistVC = ToplistVC(nibName: "ToplistVC", bundle: nil)
        //        controller5.title = "TOPLISTA"
        //        controller5.parentNavigationController = self.navigationController
        //        controllerArray.append(controller5)
        
        // Customize menu (Optional)
        let parameters: [CAPSPageMenuOption] = [
            .ScrollMenuBackgroundColor(UIColor(red: 23/255.0, green: 23/255.0, blue: 23/255.0, alpha: 1.0)),
            .ViewBackgroundColor(UIColor(red: 20.0/255.0, green: 20.0/255.0, blue: 20.0/255.0, alpha: 1.0)),
            .SelectionIndicatorColor(UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)),
            .BottomMenuHairlineColor(UIColor(red: 70.0/255.0, green: 70.0/255.0, blue: 80.0/255.0, alpha: 1.0)),
            .MenuItemFont(UIFont(name: "Avenir", size: 15.0)!),
            .MenuHeight(40.0),
            .MenuItemWidth(100),
            .CenterMenuItems(true)
        ]
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        let navheight = (navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.sharedApplication().statusBarFrame.size.height
        let frame = CGRectMake(0, navheight, view.frame.width, view.frame.height-navheight)
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: frame, pageMenuOptions: parameters)
        self.view.addSubview(pageMenu!.view)
        
    }
    
    // MARK: - Container View Controller
    override func shouldAutomaticallyForwardAppearanceMethods() -> Bool {
        return true
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
}




