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
             return _availableSongs - allSongs.count
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
                            
                            let app = UIApplication.sharedApplication().delegate as! AppDelegate
                            let context = app.managedObjectContext
                            let entity = NSEntityDescription.entityForName("SongModel", inManagedObjectContext: context)!

                            
                            
                            let fetchRequest  = NSFetchRequest(entityName: "SongModel")
                            let predicate = NSPredicate(format: "key = %@", key)
                            fetchRequest.predicate = predicate
                            
                            do {
                                let results = try context.executeFetchRequest(fetchRequest)
                                var songcount = results as! [SongModel]
                                
                                if songcount.count != 0 {
                                    print("EXISTS!")
                                } else {
                                    print("DOES NOT EXISTS!")
                                    
                                    let songModel = SongModel(entity: entity, insertIntoManagedObjectContext: context)
                                    
                                    songModel.title = title
                                    songModel.created = created
                                    songModel.lyrics = lyrics
                                    songModel.categoryTitle = categoryTitle
                                    songModel.rating = rating
                                    songModel.favorite = false
                                    songModel.key = key
                                    
                                    if let melodyTitle = songData["melodyTitle"] as? String {
                                        songModel.melodyTitle = melodyTitle
                                    } else {
                                        songModel.melodyTitle = "Okänd"
                                    }
                                    
                                    context.insertObject(songModel)
                                    
                                    do {
                                        try context.save()
                                    } catch {
                                        print("COULD NOT SAVE!")
                                    }
                                    
                                }
                                
                            } catch let err as NSError {
                                print(err.debugDescription)
                            }
                            
//                            
//                            if count == 927 {
//                                self.loadFavorites()
//                                self.saveToAllSongs()
//                                
//                                return
//                            }
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

    
    func saveToAllSongs() {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
        
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            allSongs = results as! [SongModel]
            loadCategories()
            NSNotificationCenter.defaultCenter().postNotificationName("updateSongCount", object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("reload", object: nil)
        } catch let err as NSError {
            print(err.debugDescription)
        }
    }
    
    func loadCategories() {
        for song in allSongs {
            if !allCategories.contains(song.categoryTitle!) {
                print(song.categoryTitle!)
                allCategories.append(song.categoryTitle!)
            }
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
                    
                    print(snap)
                    
                    do {
                        let results = try context.executeFetchRequest(fetchRequest)
                        var songs = results as! [SongModel]
                        
                        if !songs.isEmpty {
                            
                            var song = songs[0]
                            print(song)
                            
                            if let favorite = snap.value as? Bool {
                                song.setValue(favorite, forKey: "favorite")
                                
                                do {
                                    try song.managedObjectContext?.save()
                                    print("Set favorite \(favorite) on \(song.title) !")
                                } catch {
                                    let saveError = error as NSError
                                    print(saveError)
                                }
                            }
                        }

                        
                    } catch let err as NSError {
                        print(err.debugDescription)
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
            
            let song = snapshot.key
            
            let predicate = NSPredicate(format: "key = %@", song)
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
                            print("Set rating \(rating) on \(song.title) !")
                        } catch {
                            let saveError = error as NSError
                            print(saveError)
                        }
                    }
          
                }
                
            } catch let err as NSError {
                print(err.debugDescription)
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
        }
    }
    
    func loadToplistFromFirebase() {
        
        // Optimization => Only fetch rated songs
        
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
                                    print("Set rating \(rating) on \(song.title) !")
                                } catch {
                                    let saveError = error as NSError
                                    print(saveError)
                                }
                            }
                        }
                        
                    } catch let err as NSError {
                        print(err.debugDescription)
                    }
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName("reloadToplist", object: nil)
            }


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
        
        self._availableSongs = 0
        
        Alamofire.request(.GET, url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (key, value) in dict {
                    
                    if let title = value["title"] as? String, let created = value["created"] as? String, let lyrics = value["lyrics"] as? String, let categoryTitle = value["categoryTitle"] as? String {
                        
                        let app = UIApplication.sharedApplication().delegate as! AppDelegate
                        let context = app.managedObjectContext
                        let entity = NSEntityDescription.entityForName("SongModel", inManagedObjectContext: context)!
                        
                        let fetchRequest  = NSFetchRequest(entityName: "SongModel")
                        let predicate = NSPredicate(format: "key = %@", key)
                        fetchRequest.predicate = predicate
                        
                        do {
                            let results = try context.executeFetchRequest(fetchRequest)
                            var songcount = results as! [SongModel]
                            
                            if songcount.count != 0 {
                                print("EXISTS!")
                            } else {
                                print("DOES NOT EXISTS!")
                                
                                let songModel = SongModel(entity: entity, insertIntoManagedObjectContext: context)
                                
                                songModel.title = title
                                songModel.created = created
                                songModel.lyrics = lyrics
                                songModel.categoryTitle = categoryTitle
                                songModel.rating = 0
                                songModel.favorite = false
                                songModel.key = key
                                
                                if let melodyTitle = value["melodyTitle"] as? String {
                                    songModel.melodyTitle = melodyTitle
                                } else {
                                    songModel.melodyTitle = "Okänd"
                                }
                                
                                context.insertObject(songModel)
                                
                                do {
                                    try context.save()
                                } catch {
                                    print("COULD NOT SAVE!")
                                }
                                
                            }
                            
                        } catch let err as NSError {
                            print(err.debugDescription)
                        }
                        
                        if !allCategories.contains(categoryTitle) {
                            allCategories.append(categoryTitle)
                        }

                        self._availableSongs += 1
                    }
                }
            }
            
            print("DOWNLOADED NEW = \(self._availableSongs)")
            self.saveToAllSongs()
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



