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
import MGSwipeTableCell
import DZNEmptyDataSet
import CoreData

class ToplistVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MGSwipeTableCellDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var inSearchMode = false
    private var filteredSongs = [SongModel]()
    private var toplistSongs = allSongs
    private var refreshControl: UIRefreshControl!
    private var spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 70
        tableView.registerNib(UINib(nibName: "ToplistCell", bundle: nil), forCellReuseIdentifier: "ToplistCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .Dark
        searchBar.setImage(UIImage(named: "Menu"), forSearchBarIcon: .Bookmark, state: .Normal)
        
        navigationItem.title = "TOPPLISTA"
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ToplistVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.grayColor()
        spinner.frame = CGRectMake(0, 0, 320, 44);
        tableView.tableFooterView = spinner;
        
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).textColor = UIColor.whiteColor()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ToplistVC.reloadTableData(_:)), name: "reloadToplist", object: nil)
        
        setupResult()
    }
    
    func setupResult() {
        
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        
        let rating = 0.0
        let predicate = NSPredicate(format: "rating != \(rating)", rating)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            toplistSongs = results as! [SongModel]
            toplistSongs = self.toplistSongs.sort({Double($0.rating!) > Double($1.rating!)})
        
            self.tableView.reloadData()
            
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            Downloader.downloader.loadToplistFromFirebase()
        } else {
            self.showMessage("Ingen Internetanslutning", type: .Error , options: nil)
            refreshControl.endRefreshing()
        }
    }
    
    func reloadTableData(notification: NSNotification) {
        setupResult()
        refreshControl.endRefreshing()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        tableView.reloadData()
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
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
            filteredSongs = toplistSongs.filter({ $0.title!.lowercaseString.rangeOfString(lower) != nil })
            tableView.reloadData()
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let song: SongModel!
        
        if inSearchMode {
            song = filteredSongs[indexPath.row]
        } else {
            song = toplistSongs[indexPath.row]
        }
        
        performSegueWithIdentifier(SEUGE_DETAILVC, sender: song)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inSearchMode ? filteredSongs.count : toplistSongs.count
    }
    
    func songForIndexpath(indexPath: NSIndexPath) -> SongModel {
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
        
        switch direction {
            
        case .RightToLeft:
            
            let addButton = MGSwipeButton.init(title: "SPARA FAVORIT", backgroundColor:  UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0), callback: { (cell) -> Bool in
                
                expansionSettings.expansionColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
                
                let song = self.songForIndexpath(self.tableView.indexPathForCell(cell)!)
                
                if song.favorite != true {
                    showFavoriteAlert(true, view: self.view)
                    song.setValue(true, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).setValue(true)
                }
                
                do {
                    try song.managedObjectContext?.save()
                } catch let saveError as NSError {
                    print(saveError.debugDescription)
                }
                
                return true
            })
            
            return [addButton]
            
        case .LeftToRight:
            
            let removeButton = MGSwipeButton.init(title: "TA BORT FAVORIT", backgroundColor:  UIColor.redColor(), callback: { (cell) -> Bool in
                
                expansionSettings.expansionColor = UIColor.redColor()
                
                let song = self.songForIndexpath(self.tableView.indexPathForCell(cell)!)
                
                if song.favorite == true {
                    showFavoriteAlert(false, view: self.view)
                    song.setValue(false, forKey: "favorite")
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).removeValue()
                }
                
                do {
                    try song.managedObjectContext?.save()
                } catch let saveError as NSError {
                    print(saveError.debugDescription)
                }
                
                return true
            })
            
            return [removeButton]
        default:
            break
        }
        
        return nil
    }
    
    func swipeTableCell(cell: MGSwipeTableCell!, canSwipe direction: MGSwipeDirection) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("ToplistCell") as? ToplistCell {
            
            var song: SongModel
            
            if inSearchMode {
                song = filteredSongs[indexPath.row]
            } else {
                song = toplistSongs[indexPath.row]
            }
            
            cell.configureCell(song, number: indexPath.row)
            
            cell.delegate = self
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)
            cell.backgroundColor = UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1.0)
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
        } else {
            return SongCell()
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: "Inga sånger", attributes: attribute)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        return filteredSongs.isEmpty && !toplistSongs.isEmpty ? NSAttributedString(string: "Det finns inga sånger som matchar den angivna sökningen.", attributes: attribute) : NSAttributedString(string: "Det finns i nulägt inga sånger på topplistan.", attributes: attribute)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return filteredSongs.isEmpty && !toplistSongs.isEmpty ? UIImage(named:"EmptyDataSearch") : UIImage(named: "EmptyDataStar")
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return iPhoneType == "4" ? -50 : -70
    }
    
    func emptyDataSetDidTapView(scrollView: UIScrollView!) {
        dismisskeyboard()
    }
    
}
