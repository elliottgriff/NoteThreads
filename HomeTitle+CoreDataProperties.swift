//
//  HomeTitle+CoreDataProperties.swift
//  
//
//  Created by elliott on 9/23/22.
//
//

import Foundation
import CoreData


extension HomeTitle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HomeTitle> {
        return NSFetchRequest<HomeTitle>(entityName: "HomeTitle")
    }

    @NSManaged public var title: String?

}
