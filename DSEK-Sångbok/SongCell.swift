//
//  SongCell.swift
//  D-Sek-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var songMelodyLbl: UILabel!
    
    private var _song: Song!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.userInteractionEnabled = true

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(song: Song) {
        
        self._song = song
        self.songTitleLbl.text = song.title
        self.songMelodyLbl.text = song.melodyTitle
    }
    
}
