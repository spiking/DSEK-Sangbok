//
//  FavoritesVC.swift
//  PageMenuDemoStoryboard
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 CAPS. All rights reserved.
//

import UIKit
import AHKActionSheet

class FavoritesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {


    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var actionSheet = AHKActionSheet(title: "SORTERA EFTER")
    var parentNavigationController : UINavigationController?
    
    private var inSearchMode = false
    private var filteredSongs = [Song]()
    private var favoriteSongs = realm.objects(Song.self).filter("_favorite = 'TRUE'")
    private var mode = SORT_MODE.TITEL
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
        case BETYG = "BETYG"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "FAVORITER"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 70
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        searchBar.delegate = self
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        setupMenu()
        
        loadSortMode()
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
            case "BETYG":
                self.mode = .BETYG
            default:
                self.mode = .TITEL
            }
        }
        
        self.realoadData()
    }
    
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        actionSheet.show()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        self.realoadData()
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
        
        actionSheet.addButtonWithTitle("Skapad", type: .Default) { (actionSheet) in
            self.mode = .SKAPAD
            self.realoadData()
        }
        
        actionSheet.addButtonWithTitle("Betyg", type: .Default) { (actionSheet) in
            self.mode = .BETYG
            self.realoadData()
        }
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
    
    func realoadData() {
        
        switch self.mode {
        case .TITEL:
            self.favoriteSongs = self.favoriteSongs.sorted("_title")
            self.tableView.reloadData()
        case .MELODI:
            self.favoriteSongs = self.favoriteSongs.sorted("_melodyTitle")
            self.tableView.reloadData()
        case .SKAPAD:
            self.favoriteSongs = self.favoriteSongs.sorted("_created")
            self.tableView.reloadData()
        case .BETYG:
            self.favoriteSongs = realm.objects(Song.self).filter("_favorite = 'TRUE'").sorted("_rating")
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
            view.endEditing(true)
            tableView.reloadData()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = favoriteSongs.filter({ $0.title.lowercaseString.rangeOfString(lower) != nil })
            
            tableView.reloadData()
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let song: Song!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = favoriteSongs[indexPath.row]
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
            return favoriteSongs.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell {
            
            let song: Song!
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = favoriteSongs[indexPath.row]
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

