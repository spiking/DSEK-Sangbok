//
//  CategorySongsVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-30.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import AHKActionSheet

class CategorySongsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var category = ""
    private var categorySongs = realm.objects(Song.self)
    private var filteredSongs = [Song]()
    private var inSearchMode = false
    private var actionSheet = AHKActionSheet()
    private var mode = SORT_MODE.TITEL
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 70
        
        tableView.registerNib(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        searchBar.delegate = self
        
        navigationItem.title = "\(category)".uppercaseString
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        categorySongs = realm.objects(Song.self).filter("_categoryTitle = '\(category)'")
        
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        setupMenu()
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            return filteredSongs.count
        } else {
            return categorySongs.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("SongCell") as? SongCell {
            
            var song = categorySongs[indexPath.row]
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = categorySongs[indexPath.row]
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
            self.categorySongs = realm.objects(Song.self).filter("_categoryTitle = '\(category)'").sorted("_title")
            self.tableView.reloadData()
        case .MELODI:
            self.categorySongs = realm.objects(Song.self).filter("_categoryTitle = '\(category)'").sorted("_melodyTitle")
            self.tableView.reloadData()
        case .SKAPAD:
            self.categorySongs = realm.objects(Song.self).filter("_categoryTitle = '\(category)'").sorted("_created", ascending: false)
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
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        searchBar.text = ""
        tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        print("GO!")
        
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredSongs = categorySongs.filter({ $0.title.lowercaseString.rangeOfString(lower) != nil })
        }
        
        realoadData()
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dismisskeyboard()
        
        let song: Song!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = categorySongs[indexPath.row]
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
    
    
}
