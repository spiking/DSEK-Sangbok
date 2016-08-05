//
//  DownloadVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import MBProgressHUD
import Alamofire
import Firebase

class DownloadVC: UIViewController {
    
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var songCountLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    private var songCountBefore = 0
    private var hud = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "LADDA NER"

        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
        
        if Downloader.downloader.availableSongs >= 0 {
            songCountLbl.text = "\(Downloader.downloader.availableSongs)"
        } else {
            songCountLbl.text = "0"
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadVC.dismissDownloadIndicator(_:)), name: "dismissDownloadIndicator", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadVC.updateSongCount(_:)), name: "updateSongCount", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let lastUpdateTimestamp = NSUserDefaults.standardUserDefaults().valueForKey("LAST_UPDATE") as? String {
            dateLbl.text = "\(lastUpdate(lastUpdateTimestamp))"
        } else {
            dateLbl.text = ""
        }
    }
    
    @IBAction func downloadBtnTapped(sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
            return
        }
        
        showDownloadIndicator()
        songCountBefore = allSongs.count
        Downloader.downloader.downloadNewSongs()
    }
    
    func lastUpdate(timestamp: String) -> String {
        let dateCreated = NSDate(timeIntervalSince1970: Double(timestamp)!)
        let dateDiff = NSDate().offsetFrom(dateCreated)
        
        return dateDiff
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func updateSongCount(notification: NSNotification) {
        let availableSongs = Downloader.downloader.availableSongs
        if availableSongs >= 0 {
            songCountLbl.text = "\(availableSongs)"
        }
        
        let currentTime = NSDate().timeIntervalSince1970
        let timeSince = lastUpdate("\(currentTime)")
        
        if timeSince != "" {
            dateLbl.text = "\(timeSince)"
            NSUserDefaults.standardUserDefaults().setValue("\(currentTime)", forKey: "LAST_UPDATE")
        }

    }
    
    func dismissDownloadIndicator(notification: NSNotification) {
        
        hud.hide(true, afterDelay: 0)
        
        if songCountBefore != allSongs.count {
            let newSongs = allSongs.count - songCountBefore
            self.showMessage("Hämtade \(newSongs) nya sånger.", type: .Success , options: nil)
        } else {
            self.showMessage("Alla sånger har redan hämtats.", type: .Success , options: nil)
        }
    }
}
