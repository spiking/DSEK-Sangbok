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
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var lyricsTextView: UITextView!
    @IBOutlet weak var melodyTitleLbl: UILabel!
    @IBOutlet weak var createdLbl: UILabel!
    @IBOutlet weak var ratingLbl: UILabel!
    
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
        
        setRating()
        setupMenuButton()
        setupMenu()
        
    }
    
    func setRating() {
        
        var rating: Double = 0
        
        DataService.ds.REF_SONGS.child(self.song.key).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
            
            if let nbrOfVotes = snapshot.childSnapshotForPath("nbr_of_votes").value as? Int {
                
                if let totalRatings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                    
                    if nbrOfVotes != 0 && totalRatings != 0 {
                        
                        rating = Double(totalRatings) / Double(nbrOfVotes)
                        
                        DataService.ds.REF_SONGS.child(self.song.key).child("rating").setValue(rating)
                        
                        self.ratingLbl.text = "\(rating)"
                    } else {
                        self.ratingLbl.text = "Ej betygsatt"
                    }
                }
            }
        }
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
    
    func showFavoriteAlert(favorite: Bool) {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.CustomView
        
        var image: UIImage
        
        if favorite {
            image = UIImage(named: "Checkmark")!
            hud.labelText = "SPARAD"
        } else {
            image = UIImage(named: "Cancel")!
            hud.labelText = "BORTTAGEN"
        }
        
        hud.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        hud.customView = UIImageView(image: image)
//        hud.square = true
//        hud.minSize = CGSizeMake(125, 125)
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
            
            if snapshot.childSnapshotForPath("votes").hasChild(getUserID()) {
                
               print("USER ALREADY VOTED FOR THIS SONG!")
                
                if let oldRating = snapshot.childSnapshotForPath("votes").childSnapshotForPath(getUserID()).value as? Int {
                    
                    let difference = rating - oldRating
                    
                    if var totalRatings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                        totalRatings += difference
                        song_ref.child("total_ratings").setValue(totalRatings)
                    }
                }
                
            } else {
                
                if var votes = snapshot.childSnapshotForPath("nbr_of_votes").value as? Int {
                    votes += 1
                    song_ref.child("nbr_of_votes").setValue(votes)
                }
                
                if var ratings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                    ratings += rating
                    song_ref.child("total_ratings").setValue(ratings)
                }
            }
        }
        
        delay(0.5) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                song_ref.child("votes").child(getUserID()).setValue(rating)
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
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(self.song.key).removeValue()
                    self.showFavoriteAlert(false)
                } else {
                    self.song._favorite = "TRUE"
                    DataService.ds.REF_USERS_CURRENT.child("favorites").child(self.song.key).setValue(true)
                    self.showFavoriteAlert(true)
                }
            }
            
            
        }
    }
    
}
