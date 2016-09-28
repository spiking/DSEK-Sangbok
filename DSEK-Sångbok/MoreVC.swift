//
//  MoreVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import MBProgressHUD
import Alamofire
import Firebase
import MessageUI

class MoreVC: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var feedbackBtn: UIButton!
    @IBOutlet weak var songCountLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!

    fileprivate var songCountBefore = 0
    fileprivate var hud = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "MER"

        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
        feedbackBtn.layer.cornerRadius = 20
        feedbackBtn.clipsToBounds = true
        
        setupSongCount()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MoreVC.dismissDownloadIndicator(_:)), name: NSNotification.Name(rawValue: "dismissDownloadIndicator"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MoreVC.updateSongCount(_:)), name: NSNotification.Name(rawValue: "updateSongCount"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let lastUpdateTimestamp = UserDefaults.standard.value(forKey: "LAST_UPDATE") as? String {
            dateLbl.text = "\(lastUpdate(lastUpdateTimestamp))"
        } else {
            dateLbl.text = ""
        }
    }
    
    func setupSongCount() {
        if Downloader.downloader.availableSongs >= 0 {
            songCountLbl.text = "\(Downloader.downloader.availableSongs)"
        } else {
            songCountLbl.text = "0"
        }
    }
    
    func lastUpdate(_ timestamp: String) -> String {
        let dateCreated = Date(timeIntervalSince1970: Double(timestamp)!)
        let dateDiff = Date().offsetFrom(dateCreated)
        
        return dateDiff
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isSquare = true
    }
    
    func updateSongCount(_ notification: Notification) {
        let availableSongs = Downloader.downloader.availableSongs
        if availableSongs >= 0 {
            songCountLbl.text = "\(availableSongs)"
        }
        
        let currentTime = Date().timeIntervalSince1970
        let timeSince = lastUpdate("\(currentTime)")
        
        if timeSince != "" {
            dateLbl.text = "\(timeSince)"
            UserDefaults.standard.setValue("\(currentTime)", forKey: "LAST_UPDATE")
        }
    }
    
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            UINavigationBar.appearance().tintColor = UIColor.blue
            UINavigationBar.appearance().titleTextAttributes = [
                NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor.black
            ]
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["a.thuvesen@gmail.com"])
            present(mail, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Inget e-postkonto tillgängligt.", message: "Det verkar som du inte har anslutit ett e-postkonto till mailklienten på din iOS-enhet.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        ]
        controller.dismiss(animated: true, completion: nil)
    }
    
    func dismissDownloadIndicator(_ notification: Notification) {
        
        hud.hide(true, afterDelay: 0)
        
        if songCountBefore != allSongs.count {
            let newSongs = allSongs.count - songCountBefore
            self.showMessage("Hämtade \(newSongs) nya sånger.", type: .success , options: nil)
        } else {
            self.showMessage("Alla sånger har redan hämtats.", type: .success , options: nil)
        }
    }
    
    @IBAction func downloadBtnTapped(_ sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            self.showMessage("Ingen Internetanslutning", type: .error , options: nil)
            return
        }
        
        showDownloadIndicator()
        songCountBefore = allSongs.count
        Downloader.downloader.downloadNewSongs()
    }
    
    @IBAction func feedbackBtnTapped(_ sender: AnyObject) {
        sendEmail()
    }
}
