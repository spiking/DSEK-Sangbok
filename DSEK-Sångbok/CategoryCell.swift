//
//  CategoryCell.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-08-12.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell {

    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var categoryLbl: UILabel!
    
    fileprivate var category: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureCell(_ category: String) {
        self.category = category
        categoryLbl.text = category
    }
}
