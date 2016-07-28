//
//  ToplistVC.swift
//  PageMenuDemoStoryboard
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 CAPS. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase

class ToplistVC: UIViewController,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var parentNavigationController : UINavigationController?
    
    private var inSearchMode = false
    private var filteredSongs = [Song]()
    private var allSongs = realm.objects(Song.self)
    
    var actionSheet = AHKActionSheet(title: "SORTERA EFTER")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        tableView.estimatedRowHeight = 70
        
        navigationItem.title = "TOPPLISTA"
        
        searchBar.keyboardAppearance = .Dark
        
        tableView.registerNib(UINib(nibName: "ToplistCell", bundle: nil), forCellReuseIdentifier: "ToplistCell")
        
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu()
        
        tableView.reloadData()
        
        loadToplistFromFirebase()

    }
    
    func loadToplistFromFirebase() {
        
        DataService.ds.REF_SONGS.queryOrderedByChild("ratings").observeEventType(.Value, withBlock: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    print(snap.childSnapshotForPath("rating").value)
                    
                    
                }
            }
        })
    }
    
    
    func setupLoadingIndicator() {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.labelText = "HÄMTAR..."
        
        //        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(AllSongsVC.doSomeWorkWithProgress(hud)), userInfo: nil, repeats: true)
        
        //        hud.hide(true)
        //
        //        hud.mode = MBProgressHUDMode.CustomView
        //        let image = UIImage(named: "Checkmark")
        //        hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        //        hud.labelText = "FAVORIT"
        //        hud.customView = UIImageView(image: image)
        //        hud.square = true
        //        hud.hide(true, afterDelay: 1.0)
        
    }
    
    func doSomeWorkWithProgress() {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "Checkmark")
        hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        hud.labelText = "KLAR"
        hud.customView = UIImageView(image: image)
        hud.square = true
        hud.hide(true, afterDelay: 1.0)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        actionSheet.show()
    }
    
    func setupMenu() {
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
        actionSheet.separatorColor = UIColor(red: 30, green: 30, blue: 30, alpha: 0.2)
        actionSheet.selectedBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        let font = UIFont(name: "Avenir", size: 17)
        actionSheet.buttonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        actionSheet.disabledButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.grayColor()]
        actionSheet.destructiveButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.redColor()]
        actionSheet.cancelButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        actionSheet.addButtonWithTitle("Titel", type: .Default) { (actionSheet) in
            self.allSongs = realm.objects(Song.self).sorted("_title")
            self.tableView.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Melodi", type: .Default) { (actionSheet) in
            self.allSongs = realm.objects(Song.self).sorted("_melodyTitle")
            self.tableView.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Skapad", type: .Default) { (actionSheet) in
            self.allSongs = realm.objects(Song.self).sorted("_created")
            self.tableView.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Betyg", type: .Default) { (actionSheet) in
            
        }
    }
    
    func updateTableView() {
        self.tableView.reloadData()
    }
    
    func dismisskeyboard() {
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            view.endEditing(true)
            tableView.reloadData()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = allSongs.filter({ $0.title.lowercaseString.rangeOfString(lower) != nil })
            
            tableView.reloadData()
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
//        let song: Song!
//        
//        if inSearchMode {
//            song = filteredSongs[indexPath.row]
//        } else {
//            song = allSongs[indexPath.row]
//        }
//        
//        let detailVC = DetailVC()
//        detailVC.song = song
//        
//        parentNavigationController!.pushViewController(detailVC, animated: true)
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            return filteredSongs.count
        } else {
            return allSongs.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("ToplistCell") as? ToplistCell {
            
            let song: Song!
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = allSongs[indexPath.row]
            }
            
            let number = indexPath.row
            
            cell.configureCell(song, number: number)
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
            
        } else {
            return ToplistCell()
        }
    }
    
}
