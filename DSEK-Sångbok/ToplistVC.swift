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
    
    fileprivate var inSearchMode = false
    fileprivate var filteredSongs = [SongModel]()
    fileprivate var toplistSongs = allSongs
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 70
        tableView.register(UINib(nibName: "ToplistCell", bundle: nil), forCellReuseIdentifier: "ToplistCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .dark
        searchBar.setImage(UIImage(named: "Menu"), for: .bookmark, state: UIControlState())
        
        navigationItem.title = "TOPPLISTA"
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ToplistVC.refresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        
        spinner.hidesWhenStopped = true
        spinner.color = UIColor.gray
        spinner.frame = CGRect(x: 0, y: 0, width: 320, height: 44);
        tableView.tableFooterView = spinner;
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(ToplistVC.reloadTableData(_:)), name: NSNotification.Name(rawValue: "reloadToplist"), object: nil)
        
        setupResult()
    }
    
    func setupResult() {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
        
        let rating = 0.0
        let predicate = NSPredicate(format: "rating != \(rating)", rating)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.fetch(fetchRequest)
            toplistSongs = results as! [SongModel]
            toplistSongs = self.toplistSongs.sorted(by: {Double($0.rating!) > Double($1.rating!)})
        
            self.tableView.reloadData()
            
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
        dismisskeyboard()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    func refresh(_ sender:AnyObject) {
        
        if isConnectedToNetwork() {
            Downloader.downloader.loadToplistFromFirebase()
        } else {
            self.showMessage("Ingen Internetanslutning", type: .error , options: nil)
            refreshControl.endRefreshing()
        }
    }
    
    func reloadTableData(_ notification: Notification) {
        setupResult()
        refreshControl.endRefreshing()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        self.searchBar.text = ""
        tableView.reloadData()
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isSquare = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEUGE_DETAILVC {
            if let detailVC = segue.destination as? DetailVC {
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            view.endEditing(true)
            tableView.reloadData()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercased()
            filteredSongs = toplistSongs.filter({ $0.title!.lowercased().range(of: lower) != nil })
            tableView.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let song: SongModel!
        
        if inSearchMode {
            song = filteredSongs[(indexPath as NSIndexPath).row]
        } else {
            song = toplistSongs[(indexPath as NSIndexPath).row]
        }
        
        performSegue(withIdentifier: SEUGE_DETAILVC, sender: song)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inSearchMode ? filteredSongs.count : toplistSongs.count
    }
    
    func songForIndexpath(_ indexPath: IndexPath) -> SongModel {
        return toplistSongs[(indexPath as NSIndexPath).row]
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell!, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings!, expansionSettings: MGSwipeExpansionSettings!) -> [AnyObject]! {
        
        swipeSettings.transition = MGSwipeTransition.clipCenter
        swipeSettings.keepButtonsSwiped = false
        expansionSettings.buttonIndex = 0
        expansionSettings.threshold = 1.5
        expansionSettings.expansionLayout = MGSwipeExpansionLayout.center
        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.cubicOut
        expansionSettings.fillOnTrigger = true
        
        switch direction {
            
        case .rightToLeft:
            
            let addButton = MGSwipeButton.init(title: "SPARA FAVORIT", backgroundColor:  UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0), callback: { (cell) -> Bool in
                
                expansionSettings.expansionColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
                
                let song = self.songForIndexpath(self.tableView.indexPath(for: cell!)!)
                
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
            
            return [addButton!]
            
        case .leftToRight:
            
            let removeButton = MGSwipeButton.init(title: "TA BORT FAVORIT", backgroundColor:  UIColor.red, callback: { (cell) -> Bool in
                
                expansionSettings.expansionColor = UIColor.red
                
                let song = self.songForIndexpath(self.tableView.indexPath(for: cell!)!)
                
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
            
            return [removeButton!]
        default:
            break
        }
        
        return nil
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell!, canSwipe direction: MGSwipeDirection) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ToplistCell") as? ToplistCell {
            
            var song: SongModel
            
            if inSearchMode {
                song = filteredSongs[(indexPath as NSIndexPath).row]
            } else {
                song = toplistSongs[(indexPath as NSIndexPath).row]
            }
            
            cell.configureCell(song, number: (indexPath as NSIndexPath).row)
            
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
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: "Inga sånger", attributes: attribute)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        return filteredSongs.isEmpty && !toplistSongs.isEmpty ? NSAttributedString(string: "Det finns inga sånger som matchar den angivna sökningen.", attributes: attribute) : NSAttributedString(string: "Det finns i nulägt inga sånger på topplistan.", attributes: attribute)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return filteredSongs.isEmpty && !toplistSongs.isEmpty ? UIImage(named:"EmptyDataSearch") : UIImage(named: "EmptyDataStar")
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return iPhoneType == "4" ? -50 : -70
    }
    
    func emptyDataSetDidTap(_ scrollView: UIScrollView!) {
        dismisskeyboard()
    }
    
}
