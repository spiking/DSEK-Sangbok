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
    private var downloadedSongs = [Song]()
    private var hud = MBProgressHUD()
    private var numberOfSongs = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "LADDA NER"

        downloadBtn.layer.cornerRadius = 20
        downloadBtn.clipsToBounds = true
    }
    
    @IBAction func downloadBtnTapped(sender: AnyObject) {
        
        numberOfSongs = realm.objects(Song.self).count
        
        print("Download new songs!")
        print("Count before = \(numberOfSongs)")
        downloadNewSongs()
    }
    
    func showDownloadIndicator() {
        hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.square = true
    }
    
    func dismissDownloadIndicator() {
        
        hud.hide(true, afterDelay: 0)
        
        if numberOfSongs != realm.objects(Song.self).count {
            let newSongs = realm.objects(Song.self).count - numberOfSongs
            self.showMessage("Hämtade \(newSongs) nya sånger.", type: .Success , options: nil)
        } else {
            self.showMessage("Alla sånger är redan hämtade.", type: .Success , options: nil)
        }
    }
    
    func downloadNewSongs() {
        
        showDownloadIndicator()
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = NSURL(string: urlStr)!
        
        var newSongs = [Song]()
        
        Alamofire.request(.GET, url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (key, value) in dict {
                    
                    if let title = value["title"] as? String, let created = value["created"] as? String, let lyrics = value["lyrics"] as? String, let categoryTitle = value["categoryTitle"] as? String {
                        
                        let song = Song()
                        song._title = title
                        song._created = created
                        song._lyrics = lyrics
                        song._categoryTitle = categoryTitle
                        song._key = key
                        song._rating = 0
                        song._favorite = "FALSE"
                        
                        if let melodyTitle = value["melodyTitle"] as? String {
                             song._melodyTitle = melodyTitle
                        } else {
                            song._melodyTitle = "Okänd"
                        }
                        
                        let realm = try! Realm()

                        let newSong = realm.objectForPrimaryKey(Song.self, key: key)
                        
                        if newSong != nil {
                            print("EXIST!")
                        } else {
                            print("DOES NOT EXIST!")
                            newSongs.append(song)
                            self.saveNewSongToFirebase(key, song: value as! Dictionary<String, AnyObject>)
                            try! realm.write() {
                                realm.add(song, update: true)
                            }
                        }
                        
                    }
                }
            }
            
            self.dismissDownloadIndicator()
            
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        }
    }
    
    func saveNewSongToFirebase(key: String, song: Dictionary<String, AnyObject>) {
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if !snapshot.hasChild(key) {
                DataService.ds.REF_SONGS.child(key).setValue(song)
                DataService.ds.REF_SONGS.child(key).child("rating").setValue(0.0)
                DataService.ds.REF_SONGS.child(key).child("nbr_of_votes").setValue(0)
                DataService.ds.REF_SONGS.child(key).child("total_ratings").setValue(0)
            } else {
                print("Song already in firebase!")
            }
        }
    }
}
