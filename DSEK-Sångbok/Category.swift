//
//  Category.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-07-30.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    dynamic var _name: String!
    
    override class func primaryKey() -> String {
        return "_name"
    }
    
    var name: String {
        return _name
    }
}
