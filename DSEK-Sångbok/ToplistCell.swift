//
//  ToplistCell.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class ToplistCell: UITableViewCell {

    @IBOutlet weak var numberLbl: UILabel!
    @IBOutlet weak var songLbl: UILabel!
    @IBOutlet weak var yearLbl: UILabel!
    @IBOutlet weak var ratingLbl: UILabel!
    
    private var _song: Song!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(song: Song, number: Int) {
        
        self._song = song
        self.songLbl.text = song.title
        self.numberLbl.text = "\(number + 1)."
        
        let timestamp = song.created
        let date = NSDate(timeIntervalSince1970: Double(timestamp)!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY"
        
        self.yearLbl.text = "(\(formatter.stringFromDate(date)))"
        
        if song.rating == 0.0 {
            self.ratingLbl.text = "-"
        } else {
            self.ratingLbl.text = "\(song.rating)"
        }
        
    }
    
}
