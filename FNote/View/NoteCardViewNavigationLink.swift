//
//  NoteCardViewNavigationLink.swift
//  FNote
//
//  Created by Dara Beng on 9/20/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


/// A navigation link view for viewing or editing note card.
struct NoteCardViewNavigationLink: View {
        
    @EnvironmentObject var noteCardDataSource: NoteCardDataSource
    
    @ObservedObject var noteCard: NoteCard
    
    /// The UUID of the note card to be pushed onto the navigation view.
    @Binding var selectedNoteCardID: String?
    
    @State private var showDeleteCollectionAlert = false
    
    @State private var showChangeCollectionSheet = false
    @State private var showChangeCollectionAlert = false
    @State private var newCollectionToChange: NoteCardCollection?
    
    var onDeleted: (() -> Void)?
    
    var onPushed: (() -> Void)?
    var onPopped: (() -> Void)?
    
    var onCollectionChanged: ((NoteCardCollection) -> Void)?
        
    
    var body: some View {
        NavigationLink(destination: noteCardDetailView, tag: noteCard.uuid, selection: $selectedNoteCardID) {
            NoteCardView(noteCard: noteCard)
                .contextMenu(menuItems: contextMenuItems)
        }
        .buttonStyle(NoteCardNavigationButtonStyle())
    }
}


extension NoteCardViewNavigationLink {
    
    func contextMenuItems() -> some View {
        Group {
            Button(action: beginChangeCollection) {
                Text("Move")
                Image(systemName: "folder")
            }
            Button(action: showDeleteNoteCardAlert) {
                Text("Delete")
                Image(systemName: "trash")
            }
        }
        .alert(isPresented: $showDeleteCollectionAlert, content: deleteNoteCardAlert)
        .sheet(isPresented: $showChangeCollectionSheet, content: changeCollectionSheet)
    }
}


extension NoteCardViewNavigationLink {
    
    var noteCardDetailView: some View {
        NoteCardDetailView(noteCard: noteCard, collectionToAssign: .constant(nil))
            .navigationBarTitle("Note Card", displayMode: .inline)
            .navigationBarItems(trailing: saveNavItem)
            .onAppear(perform: onPushed)
            .onDisappear(perform: onPopped)
    }
    
    var saveNavItem: some View {
        Button(action: saveChanges) {
            Text("Save").bold()
        }
        .disabled(!noteCard.isValid())
        .opacity(noteCard.hasChangedValues() ? 1 : 0)
    }
    
    func saveChanges() {
        noteCard.objectWillChange.send() // tell the UI to refresh
        noteCardDataSource.saveUpdateContext()
    }
}


// MARK: Change Collection Sheet

extension NoteCardViewNavigationLink {
    
    func changeCollectionSheet() -> some View {
        let context = noteCard.managedObjectContext!
        let fetchRequest = NoteCardCollection.requestAllCollections()
        let collections = try? context.fetch(fetchRequest)
        let disableCollections = noteCard.collection != nil ? [noteCard.collection!] : []
        
        return NoteCardCollectionSelectionView(
            title: "Move To",
            collections: collections ?? [],
            disableCollections: disableCollections,
            onSelected: confirmChangeCollection,
            onDone: cancelChangeCollection
        )
            .alert(isPresented: $showChangeCollectionAlert, content: changeCollectionAlert)
    }
    
    func beginChangeCollection() {
        showChangeCollectionSheet = true
    }
}


// MARK: - Change Collection Alert

extension NoteCardViewNavigationLink {
    
    func changeCollectionAlert() -> Alert {
        let newCollectionName = newCollectionToChange?.name ?? ""
        let title = Text("Move Note Card")
        let message = Text("All note card's links will be removed once moved to '\(newCollectionName)' collection.")
        let cancel = Alert.Button.cancel(cancelChangeCollection)
        let move = Alert.Button.default(Text("Move"), action: commitChangeCollection)
        return Alert(title: title, message: message, primaryButton: cancel, secondaryButton: move)
    }
    
    func confirmChangeCollection(_ collection: NoteCardCollection) {
        newCollectionToChange = collection
        showChangeCollectionAlert = true
    }
    
    func commitChangeCollection() {
        guard let collection = newCollectionToChange, !noteCard.hasChangedValues() else { return }
        noteCard.collection = collection
        noteCard.relationships.removeAll()
        saveChanges()
        onCollectionChanged?(collection)
        
        newCollectionToChange = nil
        showChangeCollectionAlert = false
        showChangeCollectionSheet = false
    }
    
    func cancelChangeCollection() {
        newCollectionToChange = nil
        showChangeCollectionAlert = false
        showChangeCollectionSheet = false
    }
}


// MARK: - Delete Note Card Alert

extension NoteCardViewNavigationLink {
    
    func deleteNoteCardAlert() -> Alert {
        let collectionName = "'\(noteCard.collection!.name)'"
        let title = Text("Delete Note Card")
        let message = Text("Delete note card from the \(collectionName) collection.")
        let delete = Alert.Button.destructive(Text("Delete"), action: commitDeleteNoteCard)
        return Alert(title: title, message: message, primaryButton: .cancel(), secondaryButton: delete)
    }
    
    func showDeleteNoteCardAlert() {
        showDeleteCollectionAlert = true
    }
    
    func commitDeleteNoteCard() {
        noteCardDataSource.delete(noteCard, saveContext: true)
        onDeleted?()
        showDeleteCollectionAlert = false
    }
}


struct NoteCardViewNavigationLink_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardViewNavigationLink(noteCard: .init(), selectedNoteCardID: .constant(nil))
    }
}
