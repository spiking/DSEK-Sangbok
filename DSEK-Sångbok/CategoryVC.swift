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
    
    fileprivate var categories = allCategories
    fileprivate var filteredCategories = [String]()
    fileprivate var inSearchMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.register(UINib(nibName: "CategoryCell", bundle: nil), forCellWithReuseIdentifier: "CategoryCell")
        
        searchBar.delegate = self
        searchBar.keyboardAppearance = .dark
        
        navigationItem.title = "KATEGORIER"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        categories = allCategories.sorted()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inSearchMode = false
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inSearchMode ? filteredCategories.count : categories.count
    }

    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        dismisskeyboard()
        
        let category: String!
        
        if inSearchMode {
            category = filteredCategories[(indexPath as NSIndexPath).row]
        } else {
            category = categories[(indexPath as NSIndexPath).row]
        }
        
        performSegue(withIdentifier: "categorySongsVC", sender: category)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let numberOfColumns: CGFloat = 3
        let itemWidth = (self.collectionView!.frame.width - 2 - (numberOfColumns - 1)) / numberOfColumns
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "categorySongsVC" {
            if let categorySongsVC = segue.destination as? CategorySongsVC {
                if let category = sender as? String {
                    categorySongsVC.category = category
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismisskeyboard()
        inSearchMode = false
        searchBar.text = ""
        collectionView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == nil && searchBar.text != "" {
            inSearchMode = false
            dismisskeyboard()
        } else {
            inSearchMode = true
            let lower = searchBar.text!.lowercased()
            filteredCategories = categories.filter({ $0.lowercased().range(of: lower) != nil })
        }
        
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as? CategoryCell {
            
            var category: String
            
            if inSearchMode {
                category = filteredCategories[(indexPath as NSIndexPath).row]
            } else {
                category = categories[(indexPath as NSIndexPath).row]
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

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 19)!]
        return NSAttributedString(string: "Inga kategorier", attributes: attribute)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attribute = [NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        return filteredCategories.isEmpty && !allCategories.isEmpty ? NSAttributedString(string: "Det finns inga kategorier som matchar den angivna sökningen.", attributes: attribute) : NSAttributedString(string: "Det finns i nuläget inga kategorier.", attributes: attribute)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return filteredCategories.isEmpty && !categories.isEmpty ? UIImage(named: "EmptyDataSearch") : UIImage(named: "EmptyDataStar")
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return iPhoneType == "4" ? -50 : -70
    }
    
    func emptyDataSetDidTap(_ scrollView: UIScrollView!) {
        dismisskeyboard()
    }
}
