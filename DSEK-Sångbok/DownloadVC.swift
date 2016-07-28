//
//  DownloadVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit

class DownloadVC: UIViewController {

    @IBOutlet weak var downloadBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "LADDA NER"
        
        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
    }

    @IBAction func downloadBtnTapped(sender: AnyObject) {
        
        print("Download new songs!")
        
    }
    
}
