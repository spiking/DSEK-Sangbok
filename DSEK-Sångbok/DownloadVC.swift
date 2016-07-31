//
//  DownloadVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import MBProgressHUD
import Alamofire
import Firebase

class DownloadVC: UIViewController {
    
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var songCountLbl: UILabel!
    private var downloadedSongs = [Song]()
    private var songCountBefore = 0
    private var hud = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "LADDA NER"

        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
        
        let availableSongs = Downloader.downloader.availableSongs
        
        if availableSongs >= 0 {
            songCountLbl.text = "\(Downloader.downloader.availableSongs)"
        } else {
            songCountLbl.text = "0"
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadVC.dismissDownloadIndicator(_:)), name: "dismissDownloadIndicator", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DownloadVC.updateSongCount(_:)), name: "updateSongCount", object: nil)
    }
    
    @IBAction func downloadBtnTapped(sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            self.showMessage("Ingen internetanslutning", type: .Error , options: nil)
            return
        }
        
        showDownloadIndicator()
        songCountBefore = realm.objects(Song.self).count
        Downloader.downloader.downloadNewSongs()
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func updateSongCount(notification: NSNotification) {
        print("UPDATE \(Downloader.downloader.availableSongs)")
        let availableSongs = Downloader.downloader.availableSongs
        if availableSongs >= 0 {
            songCountLbl.text = "\(Downloader.downloader.availableSongs)"
        }
    }
    
    func dismissDownloadIndicator(notification: NSNotification) {
        
        hud.hide(true, afterDelay: 0)
        
        if songCountBefore != realm.objects(Song.self).count {
            let newSongs = realm.objects(Song.self).count - songCountBefore
            self.showMessage("Hämtade \(newSongs) nya sånger.", type: .Success , options: nil)
        } else {
            self.showMessage("Alla sånger är redan hämtade.", type: .Success , options: nil)
        }
    }
}
