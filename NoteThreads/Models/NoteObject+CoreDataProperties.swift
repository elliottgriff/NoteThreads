//
//  NoteObject+CoreDataProperties.swift
//  NoteThreads
//
//  Created by elliott on 8/29/22.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var body: String?
    @NSManaged public var date: Date?

}

extension Note : Identifiable {

}
