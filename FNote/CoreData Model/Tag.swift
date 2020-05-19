//
//  Tag+CoreDataClass.swift
//  FNote
//
//  Created by Dara Beng on 9/4/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//
//

import Foundation
import CoreData


class Tag: NSManagedObject {
    
    @NSManaged fileprivate(set) var metadata: Metadata
    
    @NSManaged fileprivate(set) var uuid: String
    @NSManaged fileprivate(set) var name: String
    @NSManaged fileprivate(set) var noteCards: Set<NoteCard>
    
    @NSManaged private var color: Int64
    
    var colorOption: ColorOption {
        set { color = newValue.rawValue }
        get { ColorOption(rawValue: color) ?? .gray }
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        uuid = UUID().uuidString
        metadata = .init(context: managedObjectContext!)
    }
}


extension Tag {
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }
    
    static func requestAllTags() -> NSFetchRequest<Tag> {
        let request = Tag.fetchRequest() as NSFetchRequest<Tag>
        let nameField = #keyPath(Tag.name)
        let metadataField = #keyPath(Tag.metadata)
        request.predicate = .init(format: "\(metadataField) != nil")
        request.sortDescriptors = [.init(key: nameField, ascending: true)]
        return request
    }
    
    static func requestUnusedTags() -> NSFetchRequest<Tag> {
        let request = Tag.fetchRequest() as NSFetchRequest<Tag>
        let noteCardsField = #keyPath(Tag.noteCards)
        request.predicate = .init(format: "\(noteCardsField).@count == 0")
        return request
    }
}


// MARK: - Object Modifier Setter

extension ObjectModifier where Object == Tag {
    
    var name: String {
        set { modifiedObject.name = newValue.trimmed().lowercased() }
        get { modifiedObject.name }
    }
    
    var color: Tag.ColorOption {
        set { modifiedObject.colorOption = newValue }
        get { modifiedObject.colorOption }
    }
}
