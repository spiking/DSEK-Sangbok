//
//  SongModel+CoreDataProperties.swift
//  DSEK-Sångbok
//
//  Created by Adam Thuvesen on 2016-08-03.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SongModel {

    @NSManaged var title: String?
    @NSManaged var created: String?
    @NSManaged var lyrics: String?
    @NSManaged var melodyTitle: String?
    @NSManaged var categoryTitle: String?
    @NSManaged var favorite: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var key: String?

}
