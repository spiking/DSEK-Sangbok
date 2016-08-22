//
//  ToplistCell.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class ToplistCell: MGSwipeTableCell {

    @IBOutlet weak var numberLbl: UILabel!
    @IBOutlet weak var songLbl: UILabel!
    @IBOutlet weak var yearLbl: UILabel!
    @IBOutlet weak var ratingLbl: UILabel!
    
    private var _song: SongModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.userInteractionEnabled = true
    }
    
    func dateCreated(timestamp: String) -> String {
        let date = NSDate(timeIntervalSince1970: Double(timestamp)!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter.stringFromDate(date)
    }
    
    func configureCell(song: SongModel, number: Int) {
        
        self._song = song
        self.songLbl.text = song.title
        self.numberLbl.text = "\(number + 1)."
        self.yearLbl.text = "(" + dateCreated(song.created!) + ")"

        if song.rating == 0.0 {
            self.ratingLbl.text = "-"
        } else {
            if let rating = song.rating as? Double {
                let ratingRounded = Double(round(10*rating)/10)
                self.ratingLbl.text = "\(ratingRounded)"
            }
        }
        
    }
    
}
