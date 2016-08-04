//
//  AllSongsVC.swift
//  PageMenuDemoStoryboard
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 CAPS. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase
import GSMessages
import MGSwipeTableCell
import DZNEmptyDataSet

import CoreData

class AllSongsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MGSwipeTableCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate  {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var inSearchMode = false
    private var filteredSongs = [SongModel]()
    private var mode = SORT_MODE.TITEL
    private var hud = MBProgressHUD()
    private var alert = false
    private var songCount = allSongs.count
    private var isDownloading = false
    private var actionSheet = AHKActionSheet(title: "SORTERA EFTER")
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "SÅNGER"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu(actionSheet)
        setupMenuOptions()
        
        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(AllSongsVC.observeNetworkConnection), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AllSongsVC.reloadTableData(_:)), name: "reload", object: nil)
        
        // Setup
        
        loadSortMode()
        authenticateUser()
        loadAllSongsFromCoreData()
        
        delay(1) {
            self.setupData()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
        saveSortMode()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSortMode()
    }
    
    func loadAllSongsFromCoreData() {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            allSongs = results as! [SongModel]
            loadCategories()
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    func loadCategories() {
        for song in allSongs {
            if !allCategories.contains(song.categoryTitle!) {
                print(song.categoryTitle!)
                allCategories.append(song.categoryTitle!)
            }
        }
    }
    
    func setupData() {
        
        if isConnectedToNetwork() {
            
            Downloader.downloader.numberOfAvailableSong()
            Downloader.downloader.loadToplistFromFirebase()
            Downloader.downloader.toplistObserver()
            
            if allSongs.isEmpty {
                self.showDownloadIndicator()
                Downloader.downloader.downloadSongsFromFirebase()
                self.isDownloading = true
            }
        }
    }
    
    func authenticateUser() {
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
            
            if error != nil {
                print(error.debugDescription)
            }
            
            let isAnonymous = user!.anonymous
            let uid = user!.uid
            
            NSUserDefaults.standardUserDefaults().setValue(uid, forKey: KEY_UID)
            
            DataService.ds.REF_USERS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
                
                if !snapshot.hasChild(getUserID()) {
                    let data = ["ACTIVE" : true]
                    DataService.ds.REF_USERS.child(getUserID()).updateChildValues(data)
                }
            }
        }
    }
    
    func observeNetworkConnection() {
        if !isConnectedToNetwork() {
            if !alert {
                self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
                alert = true
                hud.hide(true, afterDelay: 0)
            }
        } else {
            if alert {
                self.showMessage("Ansluten", type: .Success , options: nil)
                alert = false
            }
        }
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func dismissDownloadIndicator() {
        
        hud.hide(true, afterDelay: 0)
        
        if songCount == 0 {
            self.showMessage("\(allSongs.count) sånger har hämtats.", type: .Success , options: nil)
        }
        
        songCount = allSongs.count
    }
    
    func reloadTableData(notification: NSNotification) {
        self.reloadData()
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
        
        self.reloadData()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        self.reloadData()
    }
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        inSearchMode = false
        actionSheet.show()
    }
    
    func setupMenuOptions() {

        actionSheet.addButtonWithTitle("Titel", type: .Default) { (actionSheet) in
            self.mode = .TITEL
            self.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Melodi", type: .Default) { (actionSheet) in
            self.mode = .MELODI
            self.reloadData()
        }
        
        actionSheet.addButtonWithTitle("Senast Tillagd", type: .Default) { (actionSheet) in
            self.mode = .SKAPAD
            self.reloadData()
        }
    }
    
    func reloadData() {
        
        switch self.mode {
        case .TITEL:
            allSongs = allSongs.sort {
                $0.title!.compare($1.title!, locale: SWEDISH) == .OrderedAscending
            }
        case .MELODI:
            allSongs = allSongs.sort {
                $0.melodyTitle!.compare($1.melodyTitle!, locale: SWEDISH) == .OrderedAscending
            }
        case .SKAPAD:
            allSongs = allSongs.sort({$0.created > $1.created})
        default:
            break
        }
        
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
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = allSongs.filter({ $0.title!.lowercaseString.rangeOfString(lower) != nil })
        }
        
        reloadData()
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dismisskeyboard()
        
        let song: SongModel!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = allSongs[indexPath.row]
        }
        
        self.performSegueWithIdentifier(SEUGE_DETAILVC, sender: song)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEUGE_DETAILVC {
            if let detailVC = segue.destinationViewController as? DetailVC {
                if let song = sender as? SongModel {
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
    
    func songForIndexpath(indexPath: NSIndexPath) -> SongModel {
        return allSongs[indexPath.row]
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
                
                if song.favorite == true {
                    showFavoriteAlert(false, view: self.view)
                    song.setValue(false, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).removeValue()
                } else {
                    showFavoriteAlert(true, view: self.view)
                    song.setValue(true, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).setValue(true)
                }
                
                do {
                    try song.managedObjectContext?.save()
                } catch {
                    let saveError = error as NSError
                    print(saveError)
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell {
            
            var song: SongModel
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = allSongs[indexPath.row]
            }
            
            cell.configureCell(song)
            
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
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = "Inga sånger"
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: str, attributes: attribute)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        
        if filteredSongs.count == 0 && !allSongs.isEmpty {
            str = "Det finns inga sånger som matchar den angivna sökningen."
        } else {
            str = "Om sångerna inte hämtas automatiskt, klicka på ikonen nedanför."
        }
        
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        return NSAttributedString(string: str, attributes: attribute)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        var imgName = ""
        
        if filteredSongs.count == 0 && !allSongs.isEmpty  {
            imgName = "EmptyDataSearch"
        } else {
            imgName = ""
        }
        
        return UIImage(named: imgName)
    }
    
    func buttonImageForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> UIImage! {
        
        if allSongs.isEmpty {
            return UIImage(named: "DownloadMedium")
        }
        
        return UIImage(named: "")
        
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        
        if !isDownloading {
            if isConnectedToNetwork() {
                
                authenticateUser()
               
                if allSongs.isEmpty {
                     setupData()
                } else {
                    self.showMessage("\(allSongs.count) sånger har redan hämtats.", type: .Success , options: nil)
                }
               
            } else {
                self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
            }
        }
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        if iPhoneType == "4" {
            return -50
        }
        return -70
    }
    
    func emptyDataSetDidTapView(scrollView: UIScrollView!) {
        dismisskeyboard()
    }
}

