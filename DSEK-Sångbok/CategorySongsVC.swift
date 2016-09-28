//
//  CategorySongsVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-30.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import AHKActionSheet
import MGSwipeTableCell
import DZNEmptyDataSet
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class CategorySongsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, MGSwipeTableCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var _category = ""
    fileprivate var categorySongs = allSongs
    fileprivate var filteredSongs = [SongModel]()
    fileprivate var inSearchMode = false
    fileprivate var actionSheet = AHKActionSheet(title: "BETYGSÄTT SÅNG")
    fileprivate var mode = SORT_MODE.TITEL
    
    var category: String {
        get {
            return _category
        }
        set {
            _category = newValue
        }
    }
    
    enum SORT_MODE: String {
        case TITEL = "TITEL"
        case MELODI = "MELODI"
        case SKAPAD = "SKAPAD"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 70
        tableView.register(UINib(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "SongCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .dark
        searchBar.setImage(UIImage(named: "Menu"), for: .bookmark, state: UIControlState())
        
        navigationItem.title = "\(category)".uppercased()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        categorySongs = allSongs
        
        setupMenu(actionSheet!)
        setupMenuOptions()
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.white
        
        loadCategorySongs()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
        saveSortMode()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadSortMode()
    }
    
    func loadCategorySongs() {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
        
        
        let predicate = NSPredicate(format: "categoryTitle = %@", category)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.fetch(fetchRequest)
            categorySongs = results as! [SongModel]
            loadSortMode()
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    func saveSortMode() {
        UserDefaults.standard.setValue("\(self.mode)", forKey: "SORT_MODE_CAT")
    }
    
    func loadSortMode() {
        
        if let sortMode = UserDefaults.standard.value(forKey: "SORT_MODE_CAT") as? String {
            
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inSearchMode ? filteredSongs.count : categorySongs.count
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
        inSearchMode = false
        actionSheet?.show()
    }
    
    func setupMenuOptions() {
        
        actionSheet?.addButton(withTitle: "Titel", type: .default) { (actionSheet) in
            self.mode = .TITEL
            self.reloadData()
        }
        
        actionSheet?.addButton(withTitle: "Melodi", type: .default) { (actionSheet) in
            self.mode = .MELODI
            self.reloadData()
        }
        
        actionSheet?.addButton(withTitle: "Senast Tillagd", type: .default) { (actionSheet) in
            self.mode = .SKAPAD
            self.reloadData()
        }
    }
    
    func reloadData() {
        
        switch self.mode {
        case .TITEL:
            
            categorySongs = categorySongs.sorted {
                $0.title!.compare($1.title!, locale: SWEDISH as Locale) == .orderedAscending
            }
            
            self.tableView.reloadData()
        case .MELODI:
            categorySongs = categorySongs.sorted {
                $0.melodyTitle!.compare($1.melodyTitle!, locale: SWEDISH as Locale) == .orderedAscending
            }
            self.tableView.reloadData()
        case .SKAPAD:
            categorySongs = categorySongs.sorted(by: {$0.created > $1.created})
            self.tableView.reloadData()
        default:
            print("Default")
            self.tableView.reloadData()
        }
    }
    
    func dismisskeyboard() {
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        searchBar.text = ""
        reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercased()
            filteredSongs = categorySongs.filter({ $0.title!.lowercased().range(of: lower) != nil })
        }
        
        reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismisskeyboard()
        
        let song: SongModel!
        
        if inSearchMode {
            song = filteredSongs[(indexPath as NSIndexPath).row]
        } else {
            song = categorySongs[(indexPath as NSIndexPath).row]
        }
        
        performSegue(withIdentifier: SEUGE_DETAILVC, sender: song)
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
    
    func songForIndexpath(_ indexPath: IndexPath) -> SongModel {
        return categorySongs[(indexPath as NSIndexPath).row]
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell!, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        let song = self.songForIndexpath(self.tableView.indexPath(for: cell!)!)
        print(song.title)
        
        switch direction {
            
        case .rightToLeft:
            
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
            
        case .leftToRight:
            
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
            
        default:
            break
        }
        
        return true
    }
    
//    func swipeTableCell(_ cell: MGSwipeTableCell!, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings!, expansionSettings: MGSwipeExpansionSettings!) -> [AnyObject]! {
//        
//        swipeSettings.transition = MGSwipeTransition.clipCenter
//        swipeSettings.keepButtonsSwiped = false
//        expansionSettings.buttonIndex = 0
//        expansionSettings.threshold = 1.5
//        expansionSettings.expansionLayout = MGSwipeExpansionLayout.center
//        expansionSettings.triggerAnimation.easingFunction = MGSwipeEasingFunction.cubicOut
//        expansionSettings.fillOnTrigger = true
//        
//        switch direction {
//            
//        case .rightToLeft:
//            
//            let addButton = MGSwipeButton.init(title: "SPARA FAVORIT", backgroundColor:  UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0), callback: { (cell) -> Bool in
//                
//                expansionSettings.expansionColor = UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
//                
//                let song = self.songForIndexpath(self.tableView.indexPath(for: cell!)!)
//                
//                if song.favorite != true {
//                    showFavoriteAlert(true, view: self.view)
//                    song.setValue(true, forKey: "favorite")
//                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).setValue(true)
//                }
//                
//                do {
//                    try song.managedObjectContext?.save()
//                } catch let saveError as NSError {
//                    print(saveError.debugDescription)
//                }
//                
//                return true
//            })
//            
//            return [addButton!]
//            
//        case .leftToRight:
//            
//            let removeButton = MGSwipeButton.init(title: "TA BORT FAVORIT", backgroundColor:  UIColor.red, callback: { (cell) -> Bool in
//                
//                expansionSettings.expansionColor = UIColor.red
//                
//                let song = self.songForIndexpath(self.tableView.indexPath(for: cell!)!)
//                
//                if song.favorite == true {
//                    showFavoriteAlert(false, view: self.view)
//                    song.setValue(false, forKey: "favorite")
//                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(song.key!).removeValue()
//                }
//                
//                do {
//                    try song.managedObjectContext?.save()
//                } catch let saveError as NSError {
//                    print(saveError.debugDescription)
//                }
//                
//                return true
//            })
//            
//            return [removeButton!]
//        default:
//            break
//        }
//        
//        return nil
//    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell!, canSwipe direction: MGSwipeDirection) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell") as? SongCell {
            
            var song: SongModel
            
            if inSearchMode {
                song = filteredSongs[(indexPath as NSIndexPath).row]
            } else {
                song = categorySongs[(indexPath as NSIndexPath).row]
            }
            
            cell.configureCell(song)
            
            cell.delegate = self
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)
            cell.backgroundColor = UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1.0)
            cell.selectedBackgroundView = backgroundColorView
            
            cell.leftButtons = [MGSwipeButton(title: "TA BORT FAVORIT", icon: UIImage(named:""), backgroundColor: UIColor.red)]
            cell.leftSwipeSettings.transition = MGSwipeTransition.rotate3D
            
            cell.rightButtons = [MGSwipeButton(title: "SPARA FAVORIT", backgroundColor: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0))]
            cell.rightSwipeSettings.transition = MGSwipeTransition.rotate3D
            
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
        
        return filteredSongs.isEmpty && !categorySongs.isEmpty ? NSAttributedString(string:  "Det finns inga sånger som matchar den angivna sökningen.", attributes: attribute) : NSAttributedString(string:  "Det finns inga sånger som matchar den valda kategorin.", attributes: attribute)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return filteredSongs.isEmpty && !categorySongs.isEmpty ? UIImage(named: "EmptyDataSearch") : UIImage(named: "EmptyDataStar")
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return iPhoneType == "4" ? -50 : -70
    }
    
    func emptyDataSetDidTap(_ scrollView: UIScrollView!) {
        dismisskeyboard()
    }
    
}
