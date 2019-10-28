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


class Tag: NSManagedObject, ObjectValidatable {
    
    @NSManaged private(set) var uuid: String
    @NSManaged var name: String
    @NSManaged var noteCards: Set<NoteCard>
    
    
    convenience init(uuid: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.uuid = uuid
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        uuid = UUID().uuidString
    }
    
    override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }
    
    override func willSave() {
        if !isDeleted {
            validateData()
        }
        super.willSave()
    }
}


extension Tag {
    
    func isValid() -> Bool {
        hasValidInputs()
    }
    
    func hasValidInputs() -> Bool {
        !name.trimmed().isEmpty
    }
    
    func hasChangedValues() -> Bool {
        hasPersistentChangedValues
    }
    
    func validateData() {
        setPrimitiveValue(name.trimmed(), forKey: #keyPath(Tag.name))
    }
}

extension Tag {
    
    static func requestAllTags() -> NSFetchRequest<Tag> {
        let request = Tag.fetchRequest() as NSFetchRequest<Tag>
        let tagName = #keyPath(Tag.name)
        request.predicate = .init(value: true)
        request.sortDescriptors = [.init(key: tagName, ascending: true)]
        return request
    }
}


extension Tag {
    
    /// Check if a name already exists in the context.
    /// - Parameters:
    ///   - name: The name to check. The name is case sensitive.
    ///   - context: The context to check.
    /// - Returns: `true` if the name is in the context or if failed to check.
    static func isNameExisted(name: String, in context: NSManagedObjectContext) -> Bool {
        let request = requestAllTags()
        guard let tags = try? context.fetch(request) else { return true }
        return tags.contains(where: { $0.name == name })
    }
}


extension Tag {
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @objc(addNoteCardsObject:)
    @NSManaged func addToNoteCards(_ value: NoteCard)

    @objc(removeNoteCardsObject:)
    @NSManaged func removeFromNoteCards(_ value: NoteCard)

    @objc(addNoteCards:)
    @NSManaged func addToNoteCards(_ values: NSSet)

    @objc(removeNoteCards:)
    @NSManaged func removeFromNoteCards(_ values: NSSet)

}
