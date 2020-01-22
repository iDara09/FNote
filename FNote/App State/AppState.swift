//
//  AppState.swift
//  FNote
//
//  Created by Dara Beng on 1/22/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import Foundation
import CoreData


class AppState: ObservableObject {
    
    // MARK: Property
    
    /// The parent context used to read objects.
    private(set) var parentContext: NSManagedObjectContext
    
    /// The context used to create, update, and delete objects.
    private(set) var cudContext: NSManagedObjectContext?
    
    var currenNoteCards: [NoteCard] {
        currentNoteCardsFetchController.fetchedObjects ?? []
    }
    
    var collections: [NoteCardCollection] {
        collectionFetchController.fetchedObjects ?? []
    }
    
    var tags: [Tag] {
        tagFetchController.fetchedObjects ?? []
    }
    
    @Published private(set) var currentCollectionID: String? = AppCache.currentCollectionUUID
    
    
    // MARK: Fetch Controller
    
    private lazy var currentNoteCardsFetchController: NSFetchedResultsController<NoteCard> = {
        let controller = NSFetchedResultsController<NoteCard>(
            fetchRequest: NoteCard.requestNoteCards(forCollectionUUID: currentCollectionID ?? ""),
            managedObjectContext: parentContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? controller.performFetch()
        return controller
    }()
    
    private lazy var collectionFetchController: NSFetchedResultsController<NoteCardCollection> = {
        let controller = NSFetchedResultsController<NoteCardCollection>(
            fetchRequest: NoteCardCollection.requestAllCollections(),
            managedObjectContext: parentContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? controller.performFetch()
        return controller
    }()
    
    private lazy var tagFetchController: NSFetchedResultsController<Tag> = {
        let controller = NSFetchedResultsController<Tag>(
            fetchRequest: Tag.requestAllTags(),
            managedObjectContext: parentContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? controller.performFetch()
        return controller
    }()
    
    
    // MARK: Constructor
    
    init(parentContext: NSManagedObjectContext) {
        self.parentContext = parentContext
    }
}


// MARK: - Current Collection

extension AppState {
    
    func setCurrentCollection(_ collection: NoteCardCollection?) {
        currentCollectionID = collection?.uuid
        AppCache.currentCollectionUUID = collection?.uuid
    }
    
    func setCurrentCollectionFetchOption(_ option: String) {
        guard let collectionID = currentCollectionID else {
            return
        }
        
        let currentRequest = currentNoteCardsFetchController.fetchRequest
        let newRequest = NoteCard.requestNoteCards(forCollectionUUID: collectionID)
        
        currentRequest.predicate = newRequest.predicate
        currentRequest.sortDescriptors = newRequest.sortDescriptors
        
        try? currentNoteCardsFetchController.performFetch()
    }
}


// MARK: - Create & Update Object

extension AppState {
    
    func createNoteCard(with request: NoteCardCUDRequest) -> ObjectCUDResult<NoteCard> {
        let context = parentContext.newChildContext()
        let noteCard = NoteCard(context: context)
        
        request.changeContext(context)
        request.update(noteCard)
        
        if noteCard.isValid() {
            return .created(noteCard, context)
        }
        
        return .failed
    }
    
    func updateNoteCard(_ noteCard: NoteCard, with request: NoteCardCUDRequest) -> ObjectCUDResult<NoteCard> {
        let context = parentContext.newChildContext()
        let noteCardToUpdate = noteCard.get(from: context)
        
        request.changeContext(context)
        request.update(noteCardToUpdate)
            
        if noteCardToUpdate.isValid() {
            return .updated(noteCardToUpdate, context)
        }
            
        return .failed
    }
    
    func createNoteCardCollection(with request: NoteCardCollectionCUDRequest) -> ObjectCUDResult<NoteCardCollection> {
        let context = parentContext.newChildContext()
        let collection = NoteCardCollection(context: context)
        
        request.changeContext(context)
        request.update(collection)
        
        if collection.isValid() {
            return .created(collection, context)
        }
        
        return .failed
    }
    
    func updateNoteCardCollection(_ collection: NoteCardCollection, with request: NoteCardCollectionCUDRequest) -> ObjectCUDResult<NoteCardCollection> {
        let context = parentContext.newChildContext()
        let collectionToUpdate = collection.get(from: context)
        
        request.changeContext(context)
        request.update(collectionToUpdate)
        
        if collectionToUpdate.isValid() {
            return .updated(collectionToUpdate, context)
        }
        
        return .failed
    }
    
    func createTag(with request: TagCUDRequest) -> ObjectCUDResult<Tag> {
        let context = parentContext.newChildContext()
        let tag = Tag(context: context)
        
        request.changeContext(context)
        request.update(tag)
        
        if tag.isValid() {
            return .created(tag, context)
        }
        
        return .failed
    }
    
    func updateTag(_ tag: Tag, with request: TagCUDRequest) -> ObjectCUDResult<Tag> {
        let context = parentContext.newChildContext()
        let tagToUpdate = tag.get(from: context)
        
        request.changeContext(context)
        request.update(tagToUpdate)
        
        if tag.isValid() {
            return .updated(tagToUpdate, context)
        }
        
        return .failed
    }
}


// MARK: - Delete Object

extension AppState {
        
    func deleteObject<T>(_ object: T) -> ObjectCUDResult<T> where T: NSManagedObject {
        let context = parentContext.newChildContext()
        let objectToDelete = object.get(from: context)
        context.delete(objectToDelete)
        return .deleted(context)
    }
}













