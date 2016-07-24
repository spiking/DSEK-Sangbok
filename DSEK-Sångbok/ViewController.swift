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
    var songsDownloaded = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if songs.count == 0 {
            downloadSongs()
        }
        
//        for song in songs {
//            
//            let firebaseSong = ["total_ratings" : 0, "nbr_of_votes" : 0]
//            
//            DataService.ds.REF_SONGS.child(song.key).setValue(firebaseSong)
//        }
    }
    
    func downloadSongs() {
    
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
                                song._favorite = "FALSE"
                                
                                print(title)
                                
                                self.songsDownloaded.append(song)
                                
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
    
    func saveToRealm() {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            let realm = try! Realm()
            try! realm.write() {
                for song in self.songsDownloaded {
                    realm.add(song)
                }
            }
        }
    }
    
    func sortSongs() {
//        songs.sort({ $0.title > $1.title })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // MARK: - UI Setup
        
        self.title = "D-SEK SÅNGBOK"
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.tintColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        ]
        
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
        
        let controller5 : ToplistVC = ToplistVC(nibName: "ToplistVC", bundle: nil)
        controller5.title = "TOPLISTA"
        controller5.parentNavigationController = self.navigationController
        controllerArray.append(controller5)
        
        // Customize menu (Optional)
        let parameters: [CAPSPageMenuOption] = [
            .ScrollMenuBackgroundColor(UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)),
            .ViewBackgroundColor(UIColor(red: 20.0/255.0, green: 20.0/255.0, blue: 20.0/255.0, alpha: 1.0)),
            .SelectionIndicatorColor(UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)),
            .BottomMenuHairlineColor(UIColor(red: 70.0/255.0, green: 70.0/255.0, blue: 80.0/255.0, alpha: 1.0)),
            .MenuItemFont(UIFont(name: "Avenir", size: 15.0)!),
            .MenuHeight(40.0),
            .MenuItemWidth(90.0),
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




