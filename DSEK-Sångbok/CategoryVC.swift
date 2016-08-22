//
//  CategoryVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-29.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import CoreData

class CategoryVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var categories = allCategories
    private var filteredCategories = [String]()
    private var inSearchMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.registerNib(UINib(nibName: "CategoryCell", bundle: nil), forCellWithReuseIdentifier: "CategoryCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .Dark
        
        navigationItem.title = "KATEGORIER"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        categories = allCategories.sort()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inSearchMode ? filteredCategories.count : categories.count
    }

    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        dismisskeyboard()
        
        let category: String!
        
        if inSearchMode {
            category = filteredCategories[indexPath.row]
        } else {
            category = categories[indexPath.row]
        }
        
        performSegueWithIdentifier("categorySongsVC", sender: category)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let numberOfColumns: CGFloat = 3
        let itemWidth = (CGRectGetWidth(self.collectionView!.frame) - 2 - (numberOfColumns - 1)) / numberOfColumns
        
        return CGSizeMake(itemWidth, itemWidth)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
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
        collectionView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercaseString
            filteredCategories = categories.filter({ $0.lowercaseString.rangeOfString(lower) != nil })
        }
        
        collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CategoryCell", forIndexPath: indexPath) as? CategoryCell {
            
            var category: String
            
            if inSearchMode {
                category = filteredCategories[indexPath.row]
            } else {
                category = categories[indexPath.row]
            }
            
            cell.configureCell(category)
            
            let backgroundColorView = UIView()
            backgroundColorView.backgroundColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)
            cell.backgroundColor = UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1.0)
            cell.selectedBackgroundView = backgroundColorView
            
            return cell
        } else {
            return CategoryCell()
        }
    }

    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: "Inga kategorier", attributes: attribute)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        return filteredCategories.isEmpty && !allCategories.isEmpty ? NSAttributedString(string: "Det finns inga kategorier som matchar den angivna sökningen.", attributes: attribute) : NSAttributedString(string: "Det finns i nuläget inga kategorier.", attributes: attribute)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return filteredCategories.isEmpty && !categories.isEmpty ? UIImage(named: "EmptyDataSearch") : UIImage(named: "EmptyDataStar")
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return iPhoneType == "4" ? -50 : -70
    }
    
    func emptyDataSetDidTapView(scrollView: UIScrollView!) {
        dismisskeyboard()
    }
}
