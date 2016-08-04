//
//  FavoritesVC.swift
//  PageMenuDemoStoryboard
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 CAPS. All rights reserved.
//

import UIKit
import AHKActionSheet
import DZNEmptyDataSet
import MGSwipeTableCell
import MBProgressHUD
import CoreData

class FavoritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MGSwipeTableCellDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var inSearchMode = false
    private var filteredSongs = [SongModel]()
    private var favoriteSongs = allSongs
    private var mode = SORT_MODE.TITEL
    private var actionSheet = AHKActionSheet(title: "SORTERA EFTER")
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "FAVORITER"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        searchBar.delegate = self
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu(actionSheet)
        setupMenuOptions()
        
        loadSortMode()
        
        loadFavoritesFromCoreData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false        
        saveSortMode()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSortMode()
        loadFavoritesFromCoreData()
    }
    
    func loadFavoritesFromCoreData() {
        
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        
        let favorite = true
        let predicate = NSPredicate(format: "favorite = %@", favorite)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            favoriteSongs = results as! [SongModel]
            loadSortMode()
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    
    func saveSortMode() {
        NSUserDefaults.standardUserDefaults().setValue("\(self.mode)", forKey: "SORT_MODE_FAV")
    }
    
    func loadSortMode() {
        
        if let sortMode = NSUserDefaults.standardUserDefaults().valueForKey("SORT_MODE_FAV") as? String {
            
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
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        inSearchMode = false
        actionSheet.show()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        self.reloadData()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEUGE_DETAILVC {
            if let detailVC = segue.destinationViewController as? DetailVC {
                if let song = sender as? SongModel {
                    detailVC.song = song
                }
            }
        }
    }
    
    func reloadData() {
        switch self.mode {
        case .TITEL:
            favoriteSongs = favoriteSongs.sort {
                $0.title!.compare($1.title!, locale: SWEDISH) == .OrderedAscending
            }
            self.tableView.reloadData()
        case .MELODI:
            favoriteSongs = favoriteSongs.sort {
                $0.melodyTitle!.compare($1.melodyTitle!, locale: SWEDISH) == .OrderedAscending
            }
            self.tableView.reloadData()
        case .SKAPAD:
            favoriteSongs = favoriteSongs.sort({$0.created > $1.created})
            self.tableView.reloadData()
        default:
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
            view.endEditing(true)
            tableView.reloadData()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = favoriteSongs.filter({ $0.title!.lowercaseString.rangeOfString(lower) != nil })
            
            tableView.reloadData()
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let song: SongModel!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = favoriteSongs[indexPath.row]
        }
        
        self.performSegueWithIdentifier(SEUGE_DETAILVC, sender: song)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            return filteredSongs.count
        } else {
            return favoriteSongs.count
        }
    }
    
    func songForIndexpath(indexPath: NSIndexPath) -> SongModel {
        return favoriteSongs[indexPath.row]
        
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
                    print("Already favorite")
                    showFavoriteAlert(false, view: self.view)
                    song.setValue(false, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).removeValue()
                } else {
                    print("Add to favorite")
                    showFavoriteAlert(true, view: self.view)
                    song.setValue(true, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).setValue(true)
                }
                
                do {
                    try song.managedObjectContext?.save()
                    print("Save \(song.title) as favorite!")
                } catch {
                    let saveError = error as NSError
                    print(saveError)
                }
                
                self.loadFavoritesFromCoreData()
                
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
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell {
            
            var song: SongModel
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = favoriteSongs[indexPath.row]
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
        var str = "Inga favoritsånger"
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: str, attributes: attribute)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        
        if filteredSongs.count == 0 {
            str = "Det finns inga sånger som matchar den angivna sökningen."
        } else {
            str = "För att lägga till en favoritsång, swipa sången till vänster."
        }
        
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        return NSAttributedString(string: str, attributes: attribute)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = ""
        
        if filteredSongs.count == 0 && favoriteSongs.count != 0 {
            imgName = "EmptyDataSearch"
        } else {
            imgName = "EmptyDataStar"
        }
        
        return UIImage(named: imgName)
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

