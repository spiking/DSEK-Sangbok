//
//  AllSongsVC.swift
//  PageMenuDemoStoryboard
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 CAPS. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import MBProgressHUD
import Firebase
import BRYXBanner
import GSMessages

class AllSongsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var inSearchMode = false
    private var filteredSongs = [Song]()
    private var allSongs = realm.objects(Song.self)
    private var mode = SORT_MODE.TITEL
    private var hud = MBProgressHUD()
    private var downloader = Downloader()
    private var alert = false
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
        case BETYG = "BETYG"
    }
    
    var actionSheet = AHKActionSheet(title: "SORTERA EFTER")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "SÅNGER"
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self

        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu()
        
        loadSortMode()
        
        if realm.isEmpty {
            showDownloadIndicator()
        }
        
        observeSetupData()
        
        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(AllSongsVC.observeSetupData), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AllSongsVC.reloadTableData(_:)), name: "reload", object: nil)
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let favoriteAction = UITableViewRowAction(style: .Normal, title: "Favorite") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
   
        }
        
        favoriteAction.backgroundColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        
        let song = allSongs[indexPath.row]
        
        print(song.title)
        
        return [favoriteAction]
    }
    
    func observeSetupData() {
        
        // Show alert if no internet connection
        if !isConnectedToNetwork() {
            
            if !alert {
                self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
                alert = true
                hud.hide(true, afterDelay: 0)
            }
            
        } else {
            
            if alert {
                self.showMessage("Ansluten", type: .Success , options: nil)
            }
            
            if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) == nil {
                authenticateUser()
            }
            
            if realm.objects(Song.self).isEmpty {
                showDownloadIndicator()
                downloader.downloadSongsFromFirebase()
            }
            
             alert = false
        }

    }
    
    func authenticateUser() {
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            
            if error != nil {
                print(error)
            }
            
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
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func dismissDownloadIndicator() {
        
        hud.hide(true, afterDelay: 0)
        
        let count = realm.objects(Song.self).count

        self.showMessage("\(count) sånger har hämtats.", type: .Success , options: nil)

    }
    
    func reloadTableData(notification: NSNotification) {
        self.realoadData()
        dismissDownloadIndicator()
    }
    
    func saveSortMode() {
        NSUserDefaults.standardUserDefaults().setValue("\(self.mode)", forKey: "SORT_MODE_ALL")
    }
    
    func loadSortMode() {
        
        if let sortMode = NSUserDefaults.standardUserDefaults().valueForKey("SORT_MODE_ALL") as? String {
            
            switch sortMode {
            case "TITEL":
                self.mode = .TITEL
            case "MELODI":
                self.mode = .MELODI
            case "SKAPAD":
                self.mode = .SKAPAD
            default:
                self.mode = .TITEL
            }
        }
        
        self.realoadData()
    }
    
    func setupLoadingIndicator() {
        
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
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        self.realoadData()
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
        print(self.mode)
        
        saveSortMode()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSortMode()
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
            self.mode = .TITEL
            self.realoadData()
        }
        
        actionSheet.addButtonWithTitle("Melodi", type: .Default) { (actionSheet) in
            self.mode = .MELODI
            self.realoadData()
        }
        
        actionSheet.addButtonWithTitle("Senast Tillagd", type: .Default) { (actionSheet) in
            self.mode = .SKAPAD
            self.realoadData()
        }
    }
    
    func realoadData() {
        
        switch self.mode {
        case .TITEL:
            self.allSongs = realm.objects(Song.self).sorted("_title")
            self.tableView.reloadData()
        case .MELODI:
            self.allSongs = realm.objects(Song.self).sorted("_melodyTitle")
            self.tableView.reloadData()
        case .SKAPAD:
            self.allSongs = realm.objects(Song.self).sorted("_created", ascending: false)
            self.tableView.reloadData()
        default:
            print("Default")
            self.tableView.reloadData()
        }
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
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = allSongs.filter({ $0.title.lowercaseString.rangeOfString(lower) != nil })
        }
        
        realoadData()
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dismisskeyboard()
        
        let song: Song!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = allSongs[indexPath.row]
        }
        
        self.performSegueWithIdentifier("detailVC", sender: song)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailVC" {
            if let detailVC = segue.destinationViewController as? DetailVC {
                if let song = sender as? Song {
                    detailVC.song = song
                }
            }
        }
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
        if let cell = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell {
            
            let song: Song!
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = allSongs[indexPath.row]
            }
            
            cell.configureCell(song)
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
            
        } else {
            return SongCell()
        }
    }
    
}
