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
    
    fileprivate var actionSheet = AHKActionSheet(title: "BETYGSÄTT SONG")
    fileprivate var _song: SongModel!
    
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
        lyricsTextView.textAlignment = .center
        
        lyricsTextView.isScrollEnabled = false
        lyricsTextView.isScrollEnabled = true
        
        setRating()
        setupMenuButton()
        setupMenu(actionSheet!)
        setupMenuOptions()
    }
    
    override func viewDidLayoutSubviews() {
        lyricsTextView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func dateCreated(_ timestamp: String) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp)!)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date).capitalized
    }
    
    func setRating() {
        
        if !isConnectedToNetwork() {
            self.showMessage("Ingen Internetanslutning", type: .error , options: nil)
        }
        
        var rating: Double = 0
        
        DataService.ds.REF_SONGS.child(self.song.key!).observe(.value) { (snapshot: FIRDataSnapshot) in
            
            if let nbrOfVotes = snapshot.childSnapshot(forPath: "nbr_of_votes").value as? Int {
                if let totalRatings = snapshot.childSnapshot(forPath: "total_ratings").value as? Int {
                    if nbrOfVotes != 0 && totalRatings != 0 {
                        
                        rating = Double(totalRatings) / Double(nbrOfVotes)
                        DataService.ds.REF_SONGS.child(self.song.key!).child("rating").setValue(rating)
                        
                        let ratingRounded = Double(round(10*rating)/10)
                        self.ratingLbl.text = "\(ratingRounded)"
                        
                    } else {
                        self.ratingLbl.text = "Ej betygsatt"
                    }
                }
            }
        }
    }
    
    func setupMenuButton() {
        let menuButton = UIButton(type: UIButtonType.custom)
        menuButton.setImage(UIImage(named: "Menu.png"), for: UIControlState())
        menuButton.addTarget(self, action: #selector(DetailVC.showMenu), for: UIControlEvents.touchUpInside)
        menuButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        let barButton = UIBarButtonItem(customView: menuButton)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func showMenu() {
        actionSheet?.show()
    }
    
    func showGradedAlert() {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.mode = MBProgressHUDMode.customView
        let image = UIImage(named: "Checkmark")
        hud?.labelFont = UIFont(name: "Avenir-Medium", size: 18)
        hud?.labelText = "BETYGSATT"
        hud?.customView = UIImageView(image: image)
        hud?.isSquare = true
        hud?.hide(true, afterDelay: 1.0)
    }
    
    func addRatingToFirebase(_ rating: Int, completed: @escaping DownloadComplete) {
    
        DataService.ds.REF_USERS_CURRENT.child("votes").child(self.song.key!).setValue(rating)
        
        let song_ref = DataService.ds.REF_SONGS.child(self.song.key!)
        
        song_ref.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
            if snapshot.childSnapshot(forPath: "votes").hasChild(userID()) {
                if let oldRating = snapshot.childSnapshot(forPath: "votes").childSnapshot(forPath: userID()).value as? Int {
                    
                    let difference = rating - oldRating
                    
                    if var totalRatings = snapshot.childSnapshot(forPath: "total_ratings").value as? Int {
                        if totalRatings + difference >= 0 {
                            totalRatings += difference
                            song_ref.child("total_ratings").setValue(totalRatings)
                        }
                    }
                }
                
            } else {
                
                if var votes = snapshot.childSnapshot(forPath: "nbr_of_votes").value as? Int {
                    votes += 1
                    song_ref.child("nbr_of_votes").setValue(votes)
                }
                
                if var ratings = snapshot.childSnapshot(forPath: "total_ratings").value as? Int {
                    ratings += rating
                    song_ref.child("total_ratings").setValue(ratings)
                }
            }
            
            completed()
        }
    }
    
    func updateSongVotes(_ rating: Int) {
        let song_ref = DataService.ds.REF_SONGS.child(self.song.key!)
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            song_ref.child("votes").child(userID()).setValue(rating)
        }
    }
    
    func setupMenuOptions() {
        
        actionSheet?.addButton(withTitle: "5", image: UIImage(named: "StarFilled"), type: .default) { (actionSheet) in
            self.addRatingToFirebase(5) { () -> () in
                self.updateSongVotes(5)
            }
        }
        
        actionSheet?.addButton(withTitle: "4", image: UIImage(named: "StarFilled"), type: .default) { (actionSheet) in
            self.addRatingToFirebase(4) { () -> () in
                self.updateSongVotes(4)
            }
        }

        actionSheet?.addButton(withTitle: "3", image: UIImage(named: "StarFilled"), type: .default) { (actionSheet) in
            self.addRatingToFirebase(3) { () -> () in
                self.updateSongVotes(3)
            }
        }
        
        actionSheet?.addButton(withTitle: "2", image: UIImage(named: "StarFilled"), type: .default) { (actionSheet) in
            self.addRatingToFirebase(2) { () -> () in
                self.updateSongVotes(2)
            }
        }
        
        actionSheet?.addButton(withTitle: "1", image: UIImage(named: "StarFilled"), type: .default) { (actionSheet) in
            self.addRatingToFirebase(1) { () -> () in
                self.updateSongVotes(1)
            }
        }
        
        actionSheet?.addButton(withTitle: "Favorit", image: UIImage(named: "Checkmark"), type: .default) { (actionSheet) in
            
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
