//
//  Downloader.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-29.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import Firebase
import Realm
import RealmSwift
import Alamofire

class Downloader {
    
    static let downloader =  Downloader()
    
    private var _availableSongs = realm.objects(Song.self).count
    
    var availableSongs: Int {
        get {
             return _availableSongs - realm.objects(Song.self).count
        }
        set {
            _availableSongs = newValue
        }
    }
    
    func downloadSongsFromFirebase() {
        
        var count = 0
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    if let songData = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String, let rating = songData["rating"] as? Double {
                            
                            count += 1
                            
                            if count == 927 {
                                self.loadFavorites()
                                NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
                                NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
                                return
                            }
                            
                            let song = Song()
                            
                            song._title = title
                            song._created = created
                            song._lyrics = lyrics
                            song._categoryTitle = categoryTitle
                            song._rating = rating
                            song._key = key
                            song._favorite = "FALSE"
                            
                            if let melodyTitle = songData["melodyTitle"] as? String {
                                song._melodyTitle = melodyTitle
                            } else {
                                song._melodyTitle = "Okänd"
                            }
                            
                            let category = Category()
                            category._name = categoryTitle
                            
                            let realm = try! Realm()
                            try! realm.write() {
                                // No duplicates, check primary key
                                realm.add(song, update: true)
                                realm.add(category, update: true)
                            }
                        }
                    }
                }
            }
            
            self.loadFavorites()
            self.observeNumberOfAvailableSong()
            
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        }
    }
    
    func loadFavorites() {
        DataService.ds.REF_USERS_CURRENT.child("favorites").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    let song = realm.objectForPrimaryKey(Song.self, key: snap.key)
                    
                    if song != nil {
                        
                        try! realm.write() {
                            song?._favorite = "TRUE"
                            
                        }
                    }
                }
            }
        }
    }
    
    func toplistObserver() {
        
         DataService.ds.REF_SONGS.observeEventType(.ChildChanged) { (snapshot: FIRDataSnapshot!) in
            
            let song = realm.objectForPrimaryKey(Song.self, key: snapshot.key)
            
            if song != nil {
                if let rating = snapshot.childSnapshotForPath("rating").value as? Double {
                    try! realm.write() {
                        song?._rating = rating
                        NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
                        return
                    }
                }
            }
        }
    }
    
    func loadToplistFromFirebase() {
        
        // Optimization => Only fetch rated songs
        
        DataService.ds.REF_SONGS.queryOrderedByChild("rating").queryStartingAtValue(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    let song = realm.objectForPrimaryKey(Song.self, key: snap.key)
                    
                    if song != nil {
                        if let rating = snap.childSnapshotForPath("rating").value as? Double {
                            
                            print(rating)
                            
                            try! realm.write() {
                                song?._rating = rating
                            }
                        }
                    }
                }
            }
            
            
            NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
        })
    }
    
    func observeNumberOfAvailableSong() {
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = NSURL(string: urlStr)!
        
        _availableSongs = 0
        
        Alamofire.request(.GET, url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (key, value) in dict {
                    
                    if let title = value["title"] as? String, let created = value["created"] as? String, let lyrics = value["lyrics"] as? String, let categoryTitle = value["categoryTitle"] as? String {
                    
                        self._availableSongs += 1
                        
                    }
                }
            }
            
            print("OBSERVE = \(self._availableSongs)")
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
        }
    }
    
    
    func downloadNewSongs() {
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = NSURL(string: urlStr)!
        
        _availableSongs = 0
        
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
                        
                        // New song
                        
                        let newSong = realm.objectForPrimaryKey(Song.self, key: key)
                        
                        if newSong != nil {
                            print("EXIST!")
                        } else {
                            print("DOES NOT EXIST!")
                            self.saveNewSongToFirebase(key, song: value as! Dictionary<String, AnyObject>)
                            try! realm.write() {
                                realm.add(song, update: true)
                            }
                        }
                        
                        // New category
                        
                        let category = Category()
                        category._name = categoryTitle
                        
                        let newCategory = realm.objectForPrimaryKey(Category.self, key: categoryTitle)
                        
                        if newCategory != nil {
                            print("Category exists!")
                        } else {
                            print("New category!")
                            try! realm.write() {
                                realm.add(category, update: true)
                            }
                        }
                        
                        self._availableSongs += 1
                    }
                }
            }
            
            print("DOWNLOADED NEW = \(self._availableSongs)")
            
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("dismissDownloadIndicator", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        }
    }
    
    func saveNewSongToFirebase(key: String, song: Dictionary<String, AnyObject>) {
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if !snapshot.hasChild(key) {
                print("Add new song to firebase!")
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



