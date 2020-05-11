//
//  PublicCard.swift
//  FNote
//
//  Created by Dara Beng on 2/20/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import CloudKit


struct PublicCard: PublicRecord, Hashable {
    
    private(set) var record: CKRecord? = nil
    
    /// The CKRecord ID of the card's collection.
    let collectionID: String
    
    /// The CKRecord ID.
    let cardID: String
    
    var native: String
    var translation: String
    var favorited: Bool
    var formality: NoteCard.Formality
    var note: String
    var tags: [String]
    
    // The CKRecord IDs of the related cards.
    var relationships: [String]
}


extension PublicCard {
    
    static let recordType = "PublicCard"
    
    var recordName: String {
        cardID
    }
    
    enum RecordFields: RecordField {
        case collectionID
        case cardID
        case native
        case translation
        case favorited
        case formality
        case note
        case tags
        case relationships
        case collectionRef
    }
    
    
    init(record: CKRecord) {
        guard record.recordType == Self.recordType else {
            fatalError("🧨 attempt to construct \(Self.self) with unmatched record type '\(record.recordType)' 🧨")
        }
        
        self.record = record
        
        let modifier = RecordModifier<RecordFields>(record: record)
        cardID = record.recordID.recordName
        
        collectionID = modifier.string(for: .collectionID) ?? ""
        native = modifier.string(for: .native) ?? ""
        translation = modifier.string(for: .translation) ?? ""
        favorited = modifier.bool(for: .favorited)
        formality = NoteCard.Formality(rawValue: modifier.integer64(for: .formality) ?? 0)!
        note = modifier.string(for: .note) ?? ""
        relationships = modifier.stringList(for: .relationships)
        
        let formatter = PublicRecordFormatter()
        let recordTags = modifier.string(for: .tags) ?? ""
        tags = formatter.localTags(fromDatabaseTags: recordTags)
    }
    
    
    func createCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        var modifier = RecordModifier<RecordFields>(record: record)
        modifier[.collectionID] = collectionID
        modifier[.cardID] = cardID
        modifier[.native] = native
        modifier[.translation] = translation
        modifier[.favorited] = favorited
        modifier[.formality] = formality.rawValue
        modifier[.note] = note
        
        let formatter = PublicRecordFormatter()
        modifier[.tags] = formatter.databaseTags(fromLocalTags: tags)
        modifier[.relationships] = formatter.validDatabaseList(relationships)
        
        modifier.setCascadeDelete(referenceID: collectionID, field: .collectionRef)
        
        return record
    }
}


extension PublicCard {
    
    static func placeholder(collectionID: String = UUID().uuidString, cardID: String = UUID().uuidString) -> PublicCard {
        PublicCard(
            collectionID: collectionID, cardID: cardID,
            native: "----", translation: "----", favorited: false, formality: .unspecified, note: "",
            tags: [], relationships: []
        )
    }
}
