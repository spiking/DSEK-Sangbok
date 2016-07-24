//
//  DetailVC.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import MBProgressHUD
import Firebase

class DetailVC: UIViewController {
    
    var song: Song!
    var actionSheet = AHKActionSheet(title: "BETYGSÄTT SONG")
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var lyricsTextView: UITextView!
    @IBOutlet weak var melodyTitleLbl: UILabel!
    @IBOutlet weak var createdLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = song.title
        
        titleLbl.text = song.title
        melodyTitleLbl.text = song.melodyTitle
        
        let timestamp = song.created
        let date = NSDate(timeIntervalSince1970: Double(timestamp)!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        
        createdLbl.text = "\(formatter.stringFromDate(date))"
        lyricsTextView.text = song.lyrics
        lyricsTextView.font = UIFont(name: "Avenir-Book", size: 15)
        lyricsTextView.textAlignment = .Center
        
        setupMenuButton()
        setupMenu()
        
    }
    
    func setupMenuButton() {
        let menuButton = UIButton(type: UIButtonType.Custom)
        menuButton.setImage(UIImage(named: "Menu.png"), forState: UIControlState.Normal)
        menuButton.addTarget(self, action: #selector(DetailVC.showMenu), forControlEvents: UIControlEvents.TouchUpInside)
        menuButton.frame = CGRectMake(0, 0, 25, 25)
        let barButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func showMenu() {
        actionSheet.show()
    }
    
    func showFavoriteAlert() {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "Checkmark")
        hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        hud.labelText = "FAVORIT"
        hud.customView = UIImageView(image: image)
        hud.square = true
        hud.hide(true, afterDelay: 1.0)
    }
    
    
    func showGradedAlert() {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.CustomView
        let image = UIImage(named: "Checkmark")
        hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        hud.labelText = "BETYGSATT"
        hud.customView = UIImageView(image: image)
        hud.square = true
        hud.hide(true, afterDelay: 1.0)
    }
    
    func addRatingToFirebase(rating: Int) {
        
        let user_votes_ref = DataService.ds.REF_USERS_CURRENT.child("votes")
        
        user_votes_ref.child(self.song.key).setValue(rating)
        
//        DataService.ds.REF_USERS_CURRENT.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
//            
//            
//        }
        
        let song_ref = DataService.ds.REF_SONGS.child(self.song.key)

        song_ref.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if var votes = snapshot.childSnapshotForPath("nbr_of_votes").value as? Int {
                votes += 1
                song_ref.child("nbr_of_votes").setValue(votes)
                print(votes)
            }
            
            if var ratings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                ratings += rating
                song_ref.child("total_ratings").setValue(ratings)
                print(ratings)
            }
        }
    }
    
    func setupMenu() {
        actionSheet.blurTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
        actionSheet.blurRadius = 8.0
        
        if iPhoneType == "4" || iPhoneType == "5" {
            actionSheet.buttonHeight = 50.0
            actionSheet.cancelButtonHeight = 70
        } else {
            actionSheet.buttonHeight = 60.0
            actionSheet.cancelButtonHeight = 80
        }
        
        actionSheet.animationDuration = 0.5
        actionSheet.cancelButtonShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        actionSheet.separatorColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.25)
        actionSheet.selectedBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        let font = UIFont(name: "Avenir", size: 17)
        actionSheet.buttonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        actionSheet.disabledButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.grayColor()]
        actionSheet.destructiveButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.redColor()]
        actionSheet.cancelButtonTextAttributes = [NSFontAttributeName: font!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        
        
        actionSheet.addButtonWithTitle("5", image: UIImage(named: "StarFilled"), type: .Default) { (actionSheet) in
            self.addRatingToFirebase(5)
            self.showGradedAlert()
        }
        
        actionSheet.addButtonWithTitle("4", image: UIImage(named: "StarFilled"), type: .Default) { (actionSheet) in
            self.addRatingToFirebase(4)
            self.showGradedAlert()
        }
        
        actionSheet.addButtonWithTitle("3", image: UIImage(named: "StarFilled"), type: .Default) { (actionSheet) in
            self.addRatingToFirebase(3)
            self.showGradedAlert()
        }
        
        actionSheet.addButtonWithTitle("2", image: UIImage(named: "StarFilled"), type: .Default) { (actionSheet) in
            self.addRatingToFirebase(2)
            self.showGradedAlert()
        }
        
        actionSheet.addButtonWithTitle("1", image: UIImage(named: "StarFilled"), type: .Default) { (actionSheet) in
            self.addRatingToFirebase(1)
            self.showGradedAlert()
        }
        
        actionSheet.addButtonWithTitle("Favorit", image: UIImage(named: "Checkmark"), type: .Default) { (actionSheet) in
            
            try! realm.write {
                
                if self.song._favorite == "TRUE" {
                    self.song._favorite = "FALSE"
                } else {
                    self.song._favorite = "TRUE"
                }
            }
            
            self.showFavoriteAlert()
        }
    }
    
}
