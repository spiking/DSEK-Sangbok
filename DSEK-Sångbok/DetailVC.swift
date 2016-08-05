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
    
    private var actionSheet = AHKActionSheet(title: "BETYGSÄTT SONG")
    private var _song: SongModel!
    
    var song: SongModel {
        get {
            return _song
        }
        set {
            _song = newValue
        }
    }
    
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
        createdLbl.text = dateCreated(song.created!)
        
        lyricsTextView.text = song.lyrics
        lyricsTextView.font = UIFont(name: "Avenir-Roman", size: 15)
        lyricsTextView.textAlignment = .Center
        
        setRating()
        setupMenuButton()
        setupMenu(actionSheet)
        setupMenuOptions()
        
    }
    
    override func viewDidLayoutSubviews() {
        lyricsTextView.setContentOffset(CGPointZero, animated: false)
    }
    
    func dateCreated(timestamp: String) -> String {
        let date = NSDate(timeIntervalSince1970: Double(timestamp)!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.stringFromDate(date)
    }
    
    func setRating() {
        
        var rating: Double = 0
        
        DataService.ds.REF_SONGS.child(self.song.key!).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
            
            if let nbrOfVotes = snapshot.childSnapshotForPath("nbr_of_votes").value as? Int {
                if let totalRatings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                    if nbrOfVotes != 0 && totalRatings != 0 {
                        
                        rating = Double(totalRatings) / Double(nbrOfVotes)
                        
                        DataService.ds.REF_SONGS.child(self.song.key!).child("rating").setValue(rating)
                        
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
        user_votes_ref.child(self.song.key!).setValue(rating)
        
        let song_ref = DataService.ds.REF_SONGS.child(self.song.key!)
        song_ref.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if snapshot.childSnapshotForPath("votes").hasChild(userID()) {
                
                if let oldRating = snapshot.childSnapshotForPath("votes").childSnapshotForPath(userID()).value as? Int {
                    
                    let difference = rating - oldRating
                    
                    if var totalRatings = snapshot.childSnapshotForPath("total_ratings").value as? Int {
                        if totalRatings + difference >= 0 {
                            totalRatings += difference
                            song_ref.child("total_ratings").setValue(totalRatings)
                        }
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
                song_ref.child("votes").child(userID()).setValue(rating)
            }
        }
    }
    
    func setupMenuOptions() {
        
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
            
            if self.song.favorite == true {
                showFavoriteAlert(false, view: self.view)
                self.song.setValue(false, forKey: "favorite")
                DataService.ds.REF_USERS_CURRENT.child("favorites").child(self.song.key!).removeValue()
            } else {
                showFavoriteAlert(true, view: self.view)
                self.song.setValue(true, forKey: "favorite")
                DataService.ds.REF_USERS_CURRENT.child("favorites").child(self.song.key!).setValue(true)
            }
            
            do {
                try self.song.managedObjectContext?.save()
            } catch {
                let saveError = error as NSError
                print(saveError)
            }
            
        }
    }
    
}
