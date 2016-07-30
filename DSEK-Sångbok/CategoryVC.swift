//
//  CategoryVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-29.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class CategoryVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var categories = realm.objects(Category.self).sorted("_name")
    var filteredCategories = [Category]()
    var inSearchMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 70
        tableView.registerNib(UINib(nibName: "CategoryCell", bundle: nil), forCellReuseIdentifier: "CategoryCell")
        
        searchBar.delegate = self
        
        navigationItem.title = "KATEGORIER"
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        
        searchBar.keyboardAppearance = .Dark
        
        print(categories.count)
        
        // Do any additional setup after loading the view.
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
}
