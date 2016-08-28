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

    private var songCountBefore = 0
    private var hud = MBProgressHUD()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "MER"

        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
        feedbackBtn.layer.cornerRadius = 20
        feedbackBtn.clipsToBounds = true
        
        setupSongCount()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MoreVC.dismissDownloadIndicator(_:)), name: "dismissDownloadIndicator", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MoreVC.updateSongCount(_:)), name: "updateSongCount", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let lastUpdateTimestamp = NSUserDefaults.standardUserDefaults().valueForKey("LAST_UPDATE") as? String {
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
    
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            UINavigationBar.appearance().tintColor = UIColor.blueColor()
            UINavigationBar.appearance().titleTextAttributes = [
                NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor.blackColor()
            ]
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["a.thuvesen@gmail.com"])
            presentViewController(mail, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Inget e-postkonto tillgängligt.", message: "Det verkar som du inte har anslutit ett e-postkonto till mailklienten på din iOS-enhet.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 15)!, NSForegroundColorAttributeName: UIColor(red: 240/255, green: 129/255, blue: 162/255, alpha: 1.0)
        ]
        controller.dismissViewControllerAnimated(true, completion: nil)
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
    
    @IBAction func downloadBtnTapped(sender: AnyObject) {
        
        if !isConnectedToNetwork() {
            self.showMessage("Ingen Internetanslutning", type: .Error , options: nil)
            return
        }
        
        showDownloadIndicator()
        songCountBefore = allSongs.count
        Downloader.downloader.downloadNewSongs()
    }
    
    @IBAction func feedbackBtnTapped(sender: AnyObject) {
        sendEmail()
    }
}
