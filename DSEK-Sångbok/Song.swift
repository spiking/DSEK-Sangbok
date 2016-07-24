//
//  Song.swift
//  D-Sek-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-21.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

class Song: Object {
    
    dynamic var _title: String!
    dynamic var _created: String!
    dynamic var _lyrics: String!
    dynamic var _melodyTitle: String!
    dynamic var _categoryTitle: String!
    dynamic var _key: String!
    dynamic var _favorite: String!
//    dynamic var _grade: String!
    
    var title: String {
        return _title
    }
    
    var created: String {
        return _created
    }
    
    var lyrics: String {
        return _lyrics
    }
    
    var melodyTitle: String {
        return _melodyTitle
    }
    
    var categoryTitle: String {
        return _categoryTitle
    }
    
    var key: String {
        return _key
    }

//    var grade: String {
//        return _grade
//    }

}

