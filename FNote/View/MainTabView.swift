//
//  MainTabView.swift
//  FNote
//
//  Created by Dara Beng on 9/9/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


struct MainTabView: View {
    
    @ObservedObject var noteCardCollectionDataSource: NoteCardCollectionDataSource = {
        let dataSource = NoteCardCollectionDataSource(parentContext: CoreDataStack.current.mainContext)
        return dataSource
    }()
    
    @ObservedObject var noteCardDataSource: NoteCardDataSource = {
        let dataSource = NoteCardDataSource(parentContext: CoreDataStack.current.mainContext)
        return dataSource
    }()
    
    @ObservedObject var tagDataSource: TagDataSource = {
        let dataSource = TagDataSource(parentContext: CoreDataStack.current.mainContext)
        dataSource.performFetch(Tag.requestAllTags())
        return dataSource
    }()
    
    @State private var currentTabItem = Tab.card
    
    @State private var currentCollectionUUID: String?
    
    @State private var currentCollection: NoteCardCollection?
    
    let persistentStoreRemoteChangeObserver = NotificationObserver(name: .persistentStoreRemoteChange)
    
    /// A notification observer that listen to current collection did change notification.
    let collectionChangedObserver = NotificationObserver(name: .appCurrentCollectionDidChange)
    
    let collectionDeletedObserver = NotificationObserver(name: .appCollectionDidDelete)
    
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $currentTabItem) {
            if currentCollection != nil && currentCollectionUUID == currentCollection?.uuid {
                NoteCardCollectionView(collection: currentCollection!)
                    .environmentObject(noteCardDataSource)
                    .environmentObject(tagDataSource)
                    .tabItem(Tab.card.tabItem)
                    .tag(Tab.card)
            } else {
                Text("No Collection")
                    .tabItem(Tab.card.tabItem)
                    .tag(Tab.card)
            }
            
            NoteCardCollectionListView()
                .environmentObject(noteCardCollectionDataSource)
                .tabItem(Tab.collection.tabItem)
                .tag(Tab.collection)
            
            TagListView()
            .environmentObject(tagDataSource)
                .tabItem(Tab.tag.tabItem)
                .tag(Tab.tag)
            
            SettingView()
                .environmentObject(noteCardCollectionDataSource)
                .environmentObject(tagDataSource)
                .tabItem(Tab.setting.tabItem)
                .tag(Tab.setting)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: setupView)
    }
}


// MARK: Setup

extension MainTabView {
    
    func setupView() {
        loadCurrentCollection()
        setupPersistentStoreRemoteChangeObserver()
        setupCollectionObserver()
    }
    
    func setupPersistentStoreRemoteChangeObserver() {
        persistentStoreRemoteChangeObserver.onReceived = refreshFetchedObjects
    }
    
    func refreshFetchedObjects(withRemoteChange notification: Notification) {
        let history = CoreDataStack.current.historyTracker
        guard let newHistoryToken = history.token(fromRemoteChange: notification) else { return }
        guard !newHistoryToken.isEqual(history.lastToken) else { return }
        history.updateLastToken(newHistoryToken)
        
        DispatchQueue.main.async {
            switch self.currentTabItem {
            case .card:
                self.noteCardDataSource.refreshFetchedObjects()
            case .collection:
                self.noteCardCollectionDataSource.refreshFetchedObjects()
            case .tag:
                self.tagDataSource.refreshFetchedObjects()
            case .setting:
                break
            }
        }
    }
    
    /// Setup current collection observer action.
    func setupCollectionObserver() {
        collectionChangedObserver.onReceived = { notification in
            if let collection = notification.object as? NoteCardCollection {
                self.setCurrentCollection(collection)
            } else {
                self.setCurrentCollection(nil)
            }
        }
        
        collectionDeletedObserver.onReceived = { notification in
            guard let collectionUUID = notification.object as? String else { return }
            guard collectionUUID == self.currentCollectionUUID else { return }
            self.setCurrentCollection(nil)
        }
    }
    
    /// Set the current collection.
    /// - Parameter collection: The collection to be set.
    func setCurrentCollection(_ collection: NoteCardCollection?) {
        guard let collection = collection else {
            currentCollection = nil
            currentCollectionUUID = nil
            noteCardDataSource.performFetch(NoteCard.requestNone())
            return
        }
        
        guard currentCollectionUUID != collection.uuid else { return }
        
        let context = noteCardDataSource.fetchedResult.managedObjectContext
        currentCollection = context.object(with: collection.objectID) as? NoteCardCollection
        currentCollectionUUID = currentCollection?.uuid
        
        let request = NoteCard.requestNoteCards(forCollectionUUID: collection.uuid)
        noteCardDataSource.performFetch(request)
    }
    
    /// Get user's current selected note-card collection.
    func loadCurrentCollection() {
        if let uuid = AppCache.currentCollectionUUID {
            let context = noteCardDataSource.fetchedResult.managedObjectContext
            let collection = try? context.fetch(NoteCardCollection.requestCollection(withUUID: uuid)).first
            setCurrentCollection(collection)
        } else {
            setCurrentCollection(nil)
        }
    }
}


// MARK: - Tab Enum

extension MainTabView {
    
    enum Tab: Int {
        case card
        case collection
        case tag
        case setting
        
        
        func tabItem() -> some View {
            switch self {
            case .card:
                return createTabViewItem(name: "Cards", systemImage: "rectangle.fill.on.rectangle.angled.fill")
            case .collection:
                return createTabViewItem(name: "Collections", systemImage: "rectangle.stack.fill")
            case .tag:
                return createTabViewItem(name: "Tags", systemImage: "tag.fill")
            case .setting:
                return createTabViewItem(name: "Settings", systemImage: "gear")
            }
        }
        
        func createTabViewItem(name: String, systemImage: String) -> some View {
            ViewBuilder.buildBlock(Image(systemName: systemImage), Text(name))
        }
    }
}


struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
