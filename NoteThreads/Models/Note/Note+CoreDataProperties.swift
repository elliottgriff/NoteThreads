//
//  Note+CoreDataProperties.swift
//  NoteThreads
//
//  Created by elliott on 9/7/22.
//
//

import Foundation
import CoreData
import UIKit


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var body: String?
    @NSManaged public var date: Date?
    @NSManaged public var noteIndex: NSNumber?
    @NSManaged public var group: String?
    @NSManaged public var font: String?
    @NSManaged public var fontSize: NSNumber?
    @NSManaged public var color: UIColor?
    @NSManaged public var backgroundColor: UIColor?

}

extension Note : Identifiable {

}
