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
import BRYXBanner
import MGSwipeTableCell

class ToplistVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MGSwipeTableCellDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var parentNavigationController : UINavigationController?
    
    private var inSearchMode = false
    private var filteredSongs = [Song]()
    private var toplistSongs = realm.objects(Song.self).filter("_rating > 0")
    private var refreshControl: UIRefreshControl!
    private var spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    var actionSheet = AHKActionSheet(title: "SORTERA EFTER")
    var hud = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        tableView.estimatedRowHeight = 70
        
        navigationItem.title = "TOPPLISTA"
        
        searchBar.keyboardAppearance = .Dark
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ToplistVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.grayColor()
        spinner.frame = CGRectMake(0, 0, 320, 44);
        tableView.tableFooterView = spinner;
        
        tableView.registerNib(UINib(nibName: "ToplistCell", bundle: nil), forCellReuseIdentifier: "ToplistCell")
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu()
        
        self.toplistSongs = realm.objects(Song.self).filter("_rating > 0").sorted("_rating", ascending:  false)
        self.tableView.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ToplistVC.reloadTableData(_:)), name: "reloadToplist", object: nil)
        
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            Downloader.downloader.loadToplistFromFirebase()
        } else {
            self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
            refreshControl.endRefreshing()
        }
    }
    
    func reloadTableData(notification: NSNotification) {
        
        print("UPDATE!")
        
        self.toplistSongs = realm.objects(Song.self).filter("_rating > 0").sorted("_rating", ascending:  false)
        self.tableView.reloadData()
        
        refreshControl.endRefreshing()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func dismissDownloadIndicator() {
        hud.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "Checkmark")
        hud.labelText = "Klar"
        hud.customView = UIImageView(image: image)
        hud.square = true
        hud.hide(true, afterDelay: 2)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailVC" {
            if let detailVC = segue.destinationViewController as? DetailVC {
                if let song = sender as? Song {
                    detailVC.song = song
                }
            }
        }
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
            self.toplistSongs = realm.objects(Song.self).filter("_rating > 0").sorted("_title")
            self.tableView.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Melodi", type: .Default) { (actionSheet) in
            self.toplistSongs = realm.objects(Song.self).filter("_rating > 0").sorted("_melodyTitle")
            self.tableView.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Skapad", type: .Default) { (actionSheet) in
            self.toplistSongs = realm.objects(Song.self).filter("_rating > 0").sorted("_created")
            self.tableView.reloadData()
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
            filteredSongs = toplistSongs.filter({ $0.title.lowercaseString.rangeOfString(lower) != nil })
            
            tableView.reloadData()
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let song: Song!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = toplistSongs[indexPath.row]
        }
        
        self.performSegueWithIdentifier("detailVC", sender: song)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            return filteredSongs.count
        } else {
            return toplistSongs.count
        }
    }
    
    func songForIndexpath(indexPath: NSIndexPath) -> Song {
        return toplistSongs[indexPath.row]
        
    }
    
    func swipeTableCell(cell: MGSwipeTableCell!, swipeButtonsForDirection direction: MGSwipeDirection, swipeSettings: MGSwipeSettings!, expansionSettings: MGSwipeExpansionSettings!) -> [AnyObject]! {
        
        swipeSettings.transition = MGSwipeTransition.ClipCenter
        swipeSettings.keepButtonsSwiped = false
        expansionSettings.buttonIndex = 0
        expansionSettings.threshold = 1.5
        expansionSettings.expansionLayout = MGSwipeExpansionLayout.Center
        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.CubicOut
        expansionSettings.fillOnTrigger = true
        expansionSettings.expansionColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        
        if direction == MGSwipeDirection.RightToLeft {
            
            let addButton = MGSwipeButton.init(title: "SPARA FAVORIT", backgroundColor:  UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0), callback: { (cell) -> Bool in
                
                let song = self.songForIndexpath(self.tableView.indexPathForCell(cell)!)
                
                try! realm.write {
                    
                    if song.favorite == "TRUE" {
                        song._favorite = "FALSE"
                        DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key).removeValue()
                        showFavoriteAlert(false, view: self.view)
                    } else {
                        song._favorite = "TRUE"
                        DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key).setValue(true)
                        showFavoriteAlert(true, view: self.view)
                    }
                    
                    self.tableView.reloadData()
                }
                
                return true
                
            })
            
            return [addButton]
        }
        
        return nil
    }
    
    func swipeTableCell(cell: MGSwipeTableCell!, canSwipe direction: MGSwipeDirection) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("ToplistCell") as? ToplistCell {
            
            var song: Song
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = toplistSongs[indexPath.row]
            }
            
            cell.configureCell(song, number: indexPath.row)
            
            cell.delegate = self
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor.blackColor()
            cell.backgroundColor = UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1.0)
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
        } else {
            return SongCell()
        }
    }
    
}
