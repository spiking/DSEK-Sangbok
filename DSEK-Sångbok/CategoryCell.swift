//
//  CategoryCell.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-30.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class CategoryCell: UITableViewCell {

    @IBOutlet weak var categoryLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userInteractionEnabled = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(category: String) {
        categoryLbl.text = category
    }
}
