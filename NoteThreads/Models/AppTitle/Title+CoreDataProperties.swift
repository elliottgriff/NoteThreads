//
//  Title+CoreDataProperties.swift
//  NoteThreads
//
//  Created by elliott on 9/23/22.
//
//

import Foundation
import CoreData


extension Title {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Title> {
        return NSFetchRequest<Title>(entityName: "Title")
    }

    @NSManaged public var title: String?

}

extension Title : Identifiable {

}
