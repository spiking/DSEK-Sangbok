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
    
    fileprivate var _availableSongs = 0
    
    var availableSongs: Int {
        get {
            if let songs = UserDefaults.standard.value(forKey: "AVAILABLE_SONGS") as? Int {
                print("Available songs = \(songs)")
                print("All songs = \(allSongs.count)")
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
        
        var x = 0
        
        DataService.ds.REF_SONGS.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    if let songData = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        
                        if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String, let rating = songData["rating"] as? Double {
                            
                            let app = UIApplication.shared.delegate as! AppDelegate
                            let context = app.managedObjectContext
                            let entity = NSEntityDescription.entity(forEntityName: "SongModel", in: context)!
                            
                            if self.songDoesNotExist(key) {
                                
                                x += 1
                                
                                if x == 1000 {
                                    break
                                }
                                
                                let songModel = SongModel(entity: entity, insertInto: context)
                                
                                // Decode JSON (HTML)
                                
                                print("Save \(key)")
                                
                                let decodedTitle = title.decodeHTMLEntities().decodedString
                                let decodedLyrics = lyrics.decodeHTMLEntities().decodedString
                                let decodedCategoryTitle = categoryTitle.decodeHTMLEntities().decodedString
                                
                                songModel.title = decodedTitle
                                songModel.created = created
                                songModel.lyrics = decodedLyrics
                                songModel.categoryTitle = decodedCategoryTitle
                                songModel.rating = rating as NSNumber?
                                songModel.favorite = false
                                songModel.key = key
                                
                                if let melodyTitle = songData["melodyTitle"] as? String {
                                    let decodedMelodyTitle = melodyTitle.decodeHTMLEntities().decodedString
                                    songModel.melodyTitle = decodedMelodyTitle
                                } else {
                                    songModel.melodyTitle = "Okänd"
                                }
                                
                                
                                context.insert(songModel)
                                
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
            
            self.saveToAllSongs()
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateSongCount"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: nil)
        }
    }
    
    func toplistObserver() {
        
        DataService.ds.REF_SONGS.observe(.childChanged) { (snapshot: FIRDataSnapshot!) in
            
            let app = UIApplication.shared.delegate as! AppDelegate
            let context = app.managedObjectContext
            let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
            let songKey = snapshot.key
            let predicate = NSPredicate(format: "key = %@", songKey)
            fetchRequest.predicate = predicate
            
            do {
                let results = try context.fetch(fetchRequest)
                var songs = results as! [SongModel]
                
                if !songs.isEmpty {
                    
                    if let rating = snapshot.childSnapshot(forPath: "rating").value as? Double {
                        
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
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadToplist"), object: nil)
        }
    }
    
    func loadToplistFromFirebase() {
        
        // Only fetch rated songs
        
        DataService.ds.REF_SONGS.queryOrdered(byChild: "rating").queryStarting(atValue: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    
                    let app = UIApplication.shared.delegate as! AppDelegate
                    let context = app.managedObjectContext
                    let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
                    let songKey = snap.key
                    let predicate = NSPredicate(format: "key = %@", songKey)
                    fetchRequest.predicate = predicate
                    
                    do {
                        let results = try context.fetch(fetchRequest)
                        var songs = results as! [SongModel]
                        
                        if !songs.isEmpty {
                            
                            if (snap.childSnapshot(forPath: "title").value as? String) != nil {
                                
                                let song = songs[0]
                                
                                if let rating = snap.childSnapshot(forPath: "rating").value as? Double {
                                    song.setValue(rating, forKey: "rating")
                                    
                                    do {
                                        try song.managedObjectContext?.save()
                                    } catch let error as NSError {
                                        print(error.debugDescription)
                                    }
                                }
                                
                            }
                        }
                        
                    } catch let error as NSError {
                        print(error.debugDescription)
                    }
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadToplist"), object: nil)
            }
        })
    }
    
    func numberOfAvailableSong() {
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = URL(string: urlStr)!
        
        _availableSongs = 0
        
        Alamofire.request(url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (_, value) in dict {
                    if let _ = value["title"] as? String, let _ = value["created"] as? String, let _ = value["lyrics"] as? String, let _ = value["categoryTitle"] as? String {
                        self._availableSongs += 1
                    }
                }
            }
            
            UserDefaults.standard.setValue("\(NSDate().timeIntervalSince1970)", forKey: "LAST_UPDATE")
            UserDefaults.standard.setValue(self._availableSongs, forKey: "AVAILABLE_SONGS")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateSongCount"), object: nil)
        }
    }
    
    
    func downloadNewSongs() {
        
        let urlStr = "http://www.dsek.se/arkiv/sanger/api.php?showAll"
        
        let url = URL(string: urlStr)!
        
        var x = 0
        
        Alamofire.request(url).responseJSON { response in
            let result = response.result
            
            if let dict = result.value as? Dictionary<String, AnyObject> {
                
                for (key, songData) in dict {
                    
                    if let title = songData["title"] as? String, let created = songData["created"] as? String, let lyrics = songData["lyrics"] as? String, let categoryTitle = songData["categoryTitle"] as? String {
                        
                        let app = UIApplication.shared.delegate as! AppDelegate
                        let context = app.managedObjectContext
                        let entity = NSEntityDescription.entity(forEntityName: "SongModel", in: context)!
                        
                        if self.songDoesNotExist(key) {
                            
                            x += 1
                            
                            if x >= 20 {
                                break
                            }
                            
                            let songModel = SongModel(entity: entity, insertInto: context)
                            
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
                            
                            context.insert(songModel)
                            
                            do {
                                try context.save()
                            } catch let error as NSError {
                                print(error.debugDescription)
                            }
                            
                            // Save to firebase if it does not exist
                            
                            self.saveNewSongToFirebase(key, song: songData as! Dictionary<String, AnyObject>)
                            
                            if !allCategories.contains(categoryTitle) {
                                allCategories.append(categoryTitle)
                            }
                        }
                    }
                }
            }
            
            self._availableSongs
            
            self.saveToAllSongs()
            UserDefaults.standard.setValue(self._availableSongs, forKey: "AVAILABLE_SONGS")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dismissDownloadIndicator"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
            
        }
    }
    
    func saveNewSongToFirebase(_ key: String, song: Dictionary<String, AnyObject>) {
        
        DataService.ds.REF_SONGS.observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
            
            if !snapshot.hasChild(key) {
                DataService.ds.REF_SONGS.child(key).setValue(song)
                DataService.ds.REF_SONGS.child(key).child("rating").setValue(0.0)
                DataService.ds.REF_SONGS.child(key).child("nbr_of_votes").setValue(0)
                DataService.ds.REF_SONGS.child(key).child("total_ratings").setValue(0)
            }
        }
    }
    
    
    func songDoesNotExist(_ key: String) -> Bool {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
        let predicate = NSPredicate(format: "key = %@", key)
        fetchRequest.predicate = predicate
        
        do {
            let results = try context.fetch(fetchRequest)
            let songs = results as! [SongModel]
            return songs.isEmpty
        } catch let error as NSError {
            print(error.debugDescription)
        }
        
        return false
    }
    
    
    func saveToAllSongs() {
        let app = UIApplication.shared.delegate as! AppDelegate
        let context = app.managedObjectContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
        
        do {
            let results = try context.fetch(fetchRequest)
            allSongs = results as! [SongModel]
            saveCategories()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateSongCount"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reload"), object: nil)
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
    
    //    Function currently disabled
    //
    //    func loadFavorites() {
    //
    //        print(userID())
    //
    //        if (userID() == "") {
    //            return;
    //        } else {
    //            // Save
    //        }
    //
    //        DataService.ds.REF_USERS_CURRENT.child("favorites").observeSingleEvent(of: .value) { (snapshot: FIRDataSnapshot!) in
    //
    //            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
    //                for snap in snapshot {
    //
    //                    let app = UIApplication.shared.delegate as! AppDelegate
    //                    let context = app.managedObjectContext
    //                    let fetchRequest:NSFetchRequest<NSFetchRequestResult>  = NSFetchRequest(entityName: "SongModel")
    //
    //                    let songKey = snap.key
    //                    let predicate = NSPredicate(format: "key = %@", songKey)
    //                    fetchRequest.predicate = predicate
    //
    //                    print(snapshot)
    //                    print(DataService.ds.REF_USERS_CURRENT)
    //
    //                    do {
    //                        let results = try context.fetch(fetchRequest)
    //                        var songs = results as! [SongModel]
    //
    //                        if !songs.isEmpty {
    //
    //                            var song = songs[0]
    //
    //                            if let favorite = snap.value as? Bool {
    //                                song.setValue(favorite, forKey: "favorite")
    //
    //                                do {
    //                                    try song.managedObjectContext?.save()
    //                                } catch let error as NSError {
    //                                    print(error.debugDescription)
    //                                }
    //                            }
    //                        }
    //                    } catch let error as NSError {
    //                        print(error.debugDescription)
    //                    }
    //                }
    //            }
    //        }
    //    }
}


