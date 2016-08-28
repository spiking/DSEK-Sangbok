//
//  Downloader.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-29.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import Firebase
import Alamofire
import CoreData


class Downloader {
    
    static let downloader =  Downloader()
    
    private var _availableSongs = 0
    
    var availableSongs: Int {
        get {
            if let songs = NSUserDefaults.standardUserDefaults().valueForKey("AVAILABLE_SONGS") as? Int {
                return songs - allSongs.count
            } else {
                return _availableSongs
            }
        }
        set {
            _availableSongs = newValue
        }
    }
    
    func downloadSongsFromFirebase() {
        
        DataService.ds.REF_SONGS.observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    if let songData = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String, let rating = songData["rating"] as? Double {
                            
                            let app = UIApplication.sharedApplication().delegate as! AppDelegate
                            let context = app.managedObjectContext
                            let entity = NSEntityDescription.entityForName("SongModel", inManagedObjectContext: context)!
                            
                            if self.songDoesNotExist(key) {
                                
                                let songModel = SongModel(entity: entity, insertIntoManagedObjectContext: context)
                                
                                // Decode JSON (HTML)
                                
                                print("Save \(key)")
                                
                                let decodedTitle = title.decodeHTMLEntities().decodedString
                                let decodedLyrics = lyrics.decodeHTMLEntities().decodedString
                                let decodedCategoryTitle = categoryTitle.decodeHTMLEntities().decodedString
                                
                                songModel.title = decodedTitle
                                songModel.created = created
                                songModel.lyrics = decodedLyrics
                                songModel.categoryTitle = decodedCategoryTitle
                                songModel.rating = rating
                                songModel.favorite = false
                                songModel.key = key
                                
                                if let melodyTitle = songData["melodyTitle"] as? String {
                                    let decodedMelodyTitle = melodyTitle.decodeHTMLEntities().decodedString
                                    songModel.melodyTitle = decodedMelodyTitle
                                } else {
                                    songModel.melodyTitle = "Okänd"
                                }
                                
                                context.insertObject(songModel)
                                
                                do {
                                    try context.save()
                                } catch let error as NSError {
                                    print(error.debugDescription)
                                }

                            } else {
                                print("Song already exists!")
                            }
                        }
                    }
                }
            }
            
            self.loadFavorites()
            self.saveToAllSongs()
            
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        }
    }
    
    func loadFavorites() {
        DataService.ds.REF_USERS_CURRENT.child("favorites").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    let app = UIApplication.sharedApplication().delegate as! AppDelegate
                    let context = app.managedObjectContext
                    let fetchRequest  = NSFetchRequest(entityName: "SongModel")
                    
                    let songKey = snap.key
                    let predicate = NSPredicate(format: "key = %@", songKey)
                    fetchRequest.predicate = predicate
                    
                    do {
                        let results = try context.executeFetchRequest(fetchRequest)
                        var songs = results as! [SongModel]
                        
                        if !songs.isEmpty {

                            var song = songs[0]
                            
                            if let favorite = snap.value as? Bool {
                                song.setValue(favorite, forKey: "favorite")
                                
                                do {
                                    try song.managedObjectContext?.save()
                                } catch let error as NSError {
                                    print(error.debugDescription)
                                }
                            }
                        }
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                }
            }
        }
    }
    
    func toplistObserver() {
        
         DataService.ds.REF_SONGS.observeEventType(.ChildChanged) { (snapshot: FIRDataSnapshot!) in
            
            let app = UIApplication.sharedApplication().delegate as! AppDelegate
            let context = app.managedObjectContext
            let fetchRequest  = NSFetchRequest(entityName: "SongModel")
            let songKey = snapshot.key
            let predicate = NSPredicate(format: "key = %@", songKey)
            fetchRequest.predicate = predicate
            
            do {
                let results = try context.executeFetchRequest(fetchRequest)
                var songs = results as! [SongModel]
                
                if !songs.isEmpty {
                    
                    if let rating = snapshot.childSnapshotForPath("rating").value as? Double {
                        
                        var song = songs[0]
                        song.setValue(rating, forKey: "rating")
                        
                        do {
                            try song.managedObjectContext?.save()
                        } catch let error as NSError {
                            print(error.debugDescription)
                        }
                    }
                }
            } catch let error as NSError {
                print(error.debugDescription)
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
        }
    }
    
    func loadToplistFromFirebase() {
        
        // Only fetch rated songs
        
        DataService.ds.REF_SONGS.queryOrderedByChild("rating").queryStartingAtValue(1).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    let app = UIApplication.sharedApplication().delegate as! AppDelegate
                    let context = app.managedObjectContext
                    let fetchRequest  = NSFetchRequest(entityName: "SongModel")
                    let songKey = snap.key
                    let predicate = NSPredicate(format: "key = %@", songKey)
                    fetchRequest.predicate = predicate
                    
                    do {
                        let results = try context.executeFetchRequest(fetchRequest)
                        var songs = results as! [SongModel]
                        
                        if !songs.isEmpty {
                            
                            var song = songs[0]
                            
                            if let rating = snap.childSnapshotForPath("rating").value as? Double {
                                song.setValue(rating, forKey: "rating")
                                
                                do {
                                    try song.managedObjectContext?.save()
                                } catch let error as NSError {
                                    print(error.debugDescription)
                                }
                            }
                        }
                        
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
            }
        })
    }
    
    func numberOfAvailableSong() {
        
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
            
            NSUserDefaults.standardUserDefaults().setValue("\(NSDate().timeIntervalSince1970)", forKey: "LAST_UPDATE")
            NSUserDefaults.standardUserDefaults().setValue(self._availableSongs, forKey: "AVAILABLE_SONGS")
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
        }
    }
    
    
    func downloadNewSongs() {
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = NSURL(string: urlStr)!
        
        self._availableSongs = 0
        
        Alamofire.request(.GET, url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (key, songData) in dict {
                    
                    if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String {
                        
                        let app = UIApplication.sharedApplication().delegate as! AppDelegate
                        let context = app.managedObjectContext
                        let entity = NSEntityDescription.entityForName("SongModel", inManagedObjectContext: context)!
                        
                        if self.songDoesNotExist(key) {
                            
                            let songModel = SongModel(entity: entity, insertIntoManagedObjectContext: context)
                            
                            // Decode JSON (HTML)
                            
                            let decodedTitle = title.decodeHTMLEntities().decodedString
                            let decodedLyrics = lyrics.decodeHTMLEntities().decodedString
                            let decodedCategoryTitle = categoryTitle.decodeHTMLEntities().decodedString
                            
                            songModel.title = decodedTitle
                            songModel.created = created
                            songModel.lyrics = decodedLyrics
                            songModel.categoryTitle = decodedCategoryTitle
                            songModel.rating = 0
                            songModel.favorite = false
                            songModel.key = key
                            
                            if let melodyTitle = songData["melodyTitle"] as? String {
                                let decodedMelodyTitle = melodyTitle.decodeHTMLEntities().decodedString
                                songModel.melodyTitle = decodedMelodyTitle
                            } else {
                                songModel.melodyTitle = "Okänd"
                            }
                            
                            context.insertObject(songModel)
                            
                            do {
                                try context.save()
                            } catch let error as NSError {
                                print(error.debugDescription)
                            }
                            
                        } else {
                            print("Song already exists!")
                        }
                        
                        // Save to firebase if it does not exist
                        
                        self.saveNewSongToFirebase(key, song: songData as! Dictionary<String, AnyObject>)
                        
                        if !allCategories.contains(categoryTitle) {
                            allCategories.append(categoryTitle)
                        }

                        self._availableSongs += 1
                        
                    }
                }
            }
            
            self.saveToAllSongs()
            NSUserDefaults.standardUserDefaults().setValue(self._availableSongs, forKey: "AVAILABLE_SONGS")
            NSNotificationCenter.defaultCenter().postNotificationName("dismissDownloadIndicator", object: nil)
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
            }
        }
    }
    
    
    func songDoesNotExist(key: String) -> Bool {
        
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        let predicate = NSPredicate(format: "key = %@", key)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            var songs = results as! [SongModel]
            return songs.isEmpty
        } catch let error as NSError {
            print(error.debugDescription)
        }
        
        return false
    }
    
    
    func saveToAllSongs() {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            allSongs = results as! [SongModel]
            saveCategories()
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    func saveCategories() {
        for song in allSongs {
            if !allCategories.contains(song.categoryTitle!) {
                print(song.categoryTitle!)
                allCategories.append(song.categoryTitle!)
            }
        }
    }
}


