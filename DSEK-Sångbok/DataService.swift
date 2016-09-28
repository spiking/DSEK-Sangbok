//
//  DataService.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-24.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import Firebase

let URL_BASE = FIRDatabase.database().reference()

class DataService {
    
    static let ds =  DataService()
    
    fileprivate var _REF_BASE = URL_BASE
    fileprivate var _REF_USERS = URL_BASE.child("users")
    fileprivate var _REF_USERS_CURRENT = URL_BASE.child("users").child(userID())
    fileprivate var _REF_SONGS = URL_BASE.child("songs")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USERS_CURRENT: FIRDatabaseReference {
        return _REF_USERS_CURRENT
    }
    
    var REF_SONGS: FIRDatabaseReference {
        return _REF_SONGS
    }
}
