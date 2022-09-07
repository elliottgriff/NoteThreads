//
//  NoteSection+CoreDataProperties.swift
//  NoteThreads
//
//  Created by elliott on 9/7/22.
//
//

import Foundation
import CoreData


extension NoteSection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteSection> {
        return NSFetchRequest<NoteSection>(entityName: "NoteSection")
    }

    @NSManaged public var date: Date?
    @NSManaged public var title: String?
    @NSManaged public var sectionIndex: Int32

}

extension NoteSection : Identifiable {

}
