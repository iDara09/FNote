//
//  NoteCard+CoreDataClass.swift
//  FNote
//
//  Created by Dara Beng on 9/4/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//
//

import Foundation
import CoreData


class NoteCard: NSManagedObject, ObjectValidatable {
    
    @NSManaged private(set) var uuid: String
    @NSManaged var navtive: String
    @NSManaged var translation: String
    @NSManaged var isFavorited: Bool
    @NSManaged var note: String
    @NSManaged var collection: NoteCardCollection?
    @NSManaged var relationships: Set<NoteCard>
    @NSManaged var tags: Set<Tag>
    
    @NSManaged private var formalityValue: Int64
    
    var formality: Formality {
        set { formalityValue = newValue.rawValue }
        get { Formality(rawValue: formalityValue)! }
    }
    
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        uuid = UUID().uuidString
    }
    
    override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        objectWillChange.send()
    }
    
    
    enum Formality: Int64, CaseIterable {
        case unknown
        case informal
        case neutral
        case formal
        
        var title: String {
            switch self {
            case .unknown: return "No Set"
            case .informal: return "Informal"
            case .neutral: return "Neutral"
            case .formal: return "Formal"
            }
        }
    }
}


extension NoteCard {
    
    func hasTag(_ tag: Tag) -> Bool {
        tags.contains(where: { $0.uuid == tag.uuid })
    }
}


extension NoteCard {
    
    func isValid() -> Bool {
        hasValidInputs() && collection != nil
    }
    
    func hasValidInputs() -> Bool {
        !navtive.trimmed().isEmpty && !translation.trimmed().isEmpty
    }
    
    func hasChangedValues() -> Bool {
        hasPersistentChangedValues
    }
    
    func validateData() {
        navtive = navtive.trimmed()
        translation = translation.trimmed()
        note = note.trimmed()
        
        let validFormatilies = Formality.allCases.map({ $0.rawValue })
        guard !validFormatilies.contains(formalityValue) else { return }
        formality = .unknown
    }
}


extension NoteCard {
    
    static func requestNoteCards(forCollectionUUID uuid: String?) -> NSFetchRequest<NoteCard> {
        let request = NoteCard.fetchRequest() as NSFetchRequest<NoteCard>
        
        if let uuid = uuid {
            let collectionUUID = #keyPath(NoteCard.collection.uuid)
            request.predicate = .init(format: "\(collectionUUID) == %@", uuid)
            request.sortDescriptors = [.init(key: #keyPath(NoteCard.navtive), ascending: true)]
        } else {
            request.predicate = .init(value: false)
            request.sortDescriptors = []
        }
        
        return request
    }
}


extension NoteCard {
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<NoteCard> {
        return NSFetchRequest<NoteCard>(entityName: "NoteCard")
    }
    
    @objc(addRelationshipsObject:)
    @NSManaged public func addToRelationships(_ value: NoteCard)
    
    @objc(removeRelationshipsObject:)
    @NSManaged public func removeFromRelationships(_ value: NoteCard)
    
    @objc(addRelationships:)
    @NSManaged public func addToRelationships(_ values: NSSet)
    
    @objc(removeRelationships:)
    @NSManaged public func removeFromRelationships(_ values: NSSet)
    
}


extension NoteCard {
    
    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)
    
    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)
    
    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)
    
    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)
    
}


extension NoteCard {
    
    static func sampleNoteCards(count: Int) -> [NoteCard] {
        let sampleContext = CoreDataStack.sampleContext
        
        var notes = [NoteCard]()
        for note in 1...count {
            let noteCard = NoteCard(context: sampleContext)
            noteCard.navtive = "Native \(note)"
            noteCard.translation = "Translation \(note)"
            notes.append(noteCard)
        }
        
        return notes
    }
}
