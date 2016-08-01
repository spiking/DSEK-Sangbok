//
//  CategoryVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-29.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class CategoryVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var categories = realm.objects(Category.self).sorted("_name")
    private var filteredCategories = [Category]()
    private var inSearchMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.estimatedRowHeight = 70
        tableView.tableFooterView = UIView()
        tableView.registerNib(UINib(nibName: "CategoryCell", bundle: nil), forCellReuseIdentifier: "CategoryCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .Dark
        
        navigationItem.title = "KATEGORIER"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if inSearchMode {
            return filteredCategories.count
        } else {
            return categories.count
        }
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dismisskeyboard()
        
        let category: Category!
        
        if inSearchMode {
            category = filteredCategories[indexPath.row]
        } else {
            category = categories[indexPath.row]
        }
        
        print(category.name)
        
        self.performSegueWithIdentifier("categorySongsVC", sender: category.name)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "categorySongsVC" {
            if let categorySongsVC = segue.destinationViewController as? CategorySongsVC {
                if let category = sender as? String {
                    categorySongsVC.category = category
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismisskeyboard()
        
        inSearchMode = false
        searchBar.text = ""
        tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredCategories = categories.filter({ $0.name.lowercaseString.rangeOfString(lower) != nil })
        }
        
        tableView.reloadData()
    }
    
    

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell") as? CategoryCell {
            
            let category = categories[indexPath.row]
            
            print(category.name)
            
            cell.configureCell(category.name)
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor.blackColor()
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
        } else {
            return CategoryCell()
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = "Inga kategorier"
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        
        if filteredCategories.count == 0 {
            str = "Det finns inga kategorier som matchar den angivna sökningen."
        } else {
            str = "Det finns i nuläget inga kategorier."
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = "EmptyDataStar"
        return UIImage(named: imgName)
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return -70
    }
    
    func emptyDataSetDidTapView(scrollView: UIScrollView!) {
        dismisskeyboard()
    }
}
