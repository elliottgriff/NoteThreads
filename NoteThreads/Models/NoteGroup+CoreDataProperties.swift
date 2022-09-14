//
//  NoteGroup+CoreDataProperties.swift
//  NoteThreads
//
//  Created by elliott on 9/7/22.
//
//

import Foundation
import CoreData


extension NoteGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteGroup> {
        return NSFetchRequest<NoteGroup>(entityName: "NoteGroup")
    }

    @NSManaged public var date: Date?
    @NSManaged public var title: String?
    @NSManaged public var sectionIndex: Int32

}

extension NoteGroup : Identifiable {

}
