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

class Downloader {
    
    func downloadSongsFromFirebase() {
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    if let songData = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String, let rating = songData["rating"] as? Double {
                            
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
                
                 NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
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
}



