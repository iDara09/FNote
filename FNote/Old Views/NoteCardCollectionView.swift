//
//  NoteCardCollectionView.swift
//  FNote
//
//  Created by Dara Beng on 9/9/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


/// A view that displays note cards of the current selected note-card collection.
struct NoteCardCollectionView: View {
    
    var viewModel: NoteCardCollectionViewModel
    
    /// A data source used to CRUD note card.
    @EnvironmentObject var noteCardDataSource: NoteCardDataSource
    
    @EnvironmentObject var tagDataSource: TagDataSource
    
    /// The current note card collection user's selected.
    @ObservedObject var collection: NoteCardCollection
    
    @Binding var selectedNoteCardID: String?
    
    /// A note card pushed to navigation stack and viewed in NoteCardDetailView.
    @State private var noteCardToViewDetail: NoteCard?
    
    /// A view model used to handle search.
    @ObservedObject var  noteCardSearchModel: NoteCardSearchModel
    
    /// A flag used to show or hide create-new-note-card sheet.
    @State private var showCreateNewNoteCardSheet = false
    
    /// A note card collection to assign to the new note card.
    @State private var collectionToAssign: NoteCardCollection?
    
    /// A view reloader used to force reload view.
    @ObservedObject private var viewReloader = ViewForceReloader()
    
    @State private var showDiscardChangesAlert = false
        
    /// The note cards to display.
    var noteCards: [NoteCard] {
        guard noteCardSearchModel.isActive else { return noteCardDataSource.fetchedObjects }
        return noteCardSearchModel.searchResults
    }
    
    // MARK: Body
    
    var body: some View {
        NavigationView {
            NoteCardCollectionViewWrapper(viewModel: viewModel)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            ScrollView(.vertical, showsIndicators: true) {
//                VStack {
                    
//                    SearchTextField(
//                        searchField: noteCardSearchModel.searchField,
//                        searchOption: noteCardSearchModel.searchOption,
//                        onCancel: noteCardSearchModel.reset
//                    )
//                        .padding(.horizontal, 8)
                    
//                    ForEach(noteCards, id: \.uuid) { noteCard in
////                        NoteCardViewNavigationLink(
////                            noteCard: noteCard,
////                            selectedNoteCardID: self.$selectedNoteCardID,
////                            onDeleted: self.handleNoteCardDeleted,
////                            onPushed: { self.noteCardToViewDetail = noteCard },
////                            onPopped: self.checkNoteCardUnsavedChanges,
////                            onCollectionChanged: self.handleNoteCardCollectionChanged
////                        )
//                        NoteCardCellWrapper(
//                            noteCard: noteCard,
//                            onQuickButtonTapped: { print($0) }
//                        )
//                            .frame(height: NoteCardCell.Style.regular.height)
//                    }
//                }
//                .padding()
//            }
            .navigationBarTitle(collection.name)
            .navigationBarItems(trailing: createNewNoteCardNavItem)
            .onAppear(perform: setupView)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showDiscardChangesAlert, content: { self.discardNoteCardChangesAlert })
        .sheet(
            isPresented: $showCreateNewNoteCardSheet,
            onDismiss: cancelCreateNewNoteCard,
            content: createNewNoteCardSheet
        )
    }
}


// MARK: - Create View and Method

extension NoteCardCollectionView {
    
    /// A nav bar button for creating new note card.
    var createNewNoteCardNavItem: some View {
        Button(action: beginCreateNewNoteCard) {
            Image(systemName: "plus")
                .imageScale(.large)
        }
        .buttonStyle(NavigationItemIconStyle())
    }
    
    /// A sheet view for creating new note card.
    func createNewNoteCardSheet() -> some View {
        let cancelButton = Button("Cancel", action: cancelCreateNewNoteCard)
        
        let createButton = Button(action: commitCreateNewNoteCard) {
            Text("Create").bold()
        }
        .disabled(!noteCardDataSource.newObject!.hasValidInputs())
        .onReceive(noteCardDataSource.newObject!.objectWillChange) { _ in
            self.viewReloader.forceReload()
        }
        
        return NavigationView {
            NoteCardDetailView(noteCard: noteCardDataSource.newObject!, collectionToAssign: $collectionToAssign)
                .environmentObject(noteCardDataSource)
                .environmentObject(tagDataSource)
                .navigationBarTitle("New Note Card", displayMode: .inline)
                .navigationBarItems(leading: cancelButton, trailing: createButton)
                .onDisappear(perform: { self.collectionToAssign = nil })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    /// Start creating new note card.
    func beginCreateNewNoteCard() {
        collectionToAssign = collection.get(from: noteCardDataSource.createContext)
        noteCardDataSource.prepareNewObject()
        showCreateNewNoteCardSheet = true
    }
    
    /// Save the new note card.
    func commitCreateNewNoteCard() {
        // grab the current collection from the same context as the new note card
        // then assign it to the new note card's collection
        // will unwrapped optional values because they must exist
        let newNoteCard = noteCardDataSource.newObject!
        newNoteCard.collection = collectionToAssign
    
        let saveResult = noteCardDataSource.saveNewObject()
        
        switch saveResult {
        
        case .saved:
            noteCardDataSource.discardNewObject()
            viewReloader.forceReload()
            showCreateNewNoteCardSheet = false
        
        case .failed: break // TODO: show alert to inform user
        
        case .unchanged: break // this case will never happens for create
        }
    }
    
    /// Cancel creating new note card.
    func cancelCreateNewNoteCard() {
        noteCardDataSource.discardNewObject()
        noteCardDataSource.discardCreateContext()
        showCreateNewNoteCardSheet = false
    }
    
    func deleteNoteCard(_ notecard: NoteCard) {
        noteCardDataSource.delete(notecard, saveContext: true)
        viewReloader.forceReload()
    }
}


// MARK: - NoteCard Discard Alert

extension NoteCardCollectionView {
    
    var discardNoteCardChangesAlert: Alert {
        // can unwrap this one because `checkUnsavedChanges` already check
        let noteCard = noteCardToViewDetail!
        
        let revert = Alert.Button.default(Text("Revert"), action: discardNoteCardChanges)
        
        if noteCard.isValid() {
            let title = Text("Unsaved Changes")
            let message = Text("There are unsaved changes.\nWould you like to save the changes?")
            let save = Alert.Button.default(Text("Save").bold(), action: saveNoteCardChanges)
            return Alert(title: title, message: message, primaryButton: revert, secondaryButton: save)
        } else {
            let title = Text("Invalid Input")
            let message = Text("Your changes have not been saved. After dismissing this message all unsaved changes will be reverted.")
            return Alert(title: title, message: message, dismissButton: revert)
        }
    }
    
    /// Check and show discard alert if there are unsaved changes.
    func checkNoteCardUnsavedChanges() {
        guard let noteCard = noteCardToViewDetail else { return }
        if noteCard.hasChangedValues() {
            showDiscardChangesAlert = true
        } else {
            noteCardDataSource.discardUpdateContext()
            noteCardToViewDetail = nil
        }
    }
    
    func discardNoteCardChanges() {
        guard let noteCard = noteCardToViewDetail else { return }
        noteCard.objectWillChange.send() // tell the UI to refresh
        noteCardDataSource.discardUpdateContext()
        noteCardToViewDetail = nil
    }
    
    func saveNoteCardChanges() {
        guard let noteCard = noteCardToViewDetail else { return }
        noteCard.objectWillChange.send() // tell the UI to refresh
        noteCardDataSource.saveUpdateContext()
        noteCardToViewDetail = nil
    }
}


// MARK: - Note Card Navigation Link

extension NoteCardCollectionView {
    
    func handleNoteCardDeleted() {
        viewReloader.forceReload()
        if noteCardSearchModel.isActive {
            noteCardSearchModel.refetchNoteCards()
        }
    }
    
    func handleNoteCardCollectionChanged(_ collection: NoteCardCollection) {
        if noteCardSearchModel.isActive {
            noteCardSearchModel.refetchNoteCards()
        }
    }
}

// MARK: - Setup & Fetch Method

extension NoteCardCollectionView {
    
    /// Prepare view and data when view appears.
    func setupView() {
        collection.objectWillChange.send()
        noteCardSearchModel.context = noteCardDataSource.updateContext
        noteCardSearchModel.matchingCollectionUUID = collection.uuid
        checkNoteCardUnsavedChanges()
    }
}


struct NoteCardCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardCollectionView(viewModel: .init(), collection: .init(), selectedNoteCardID: .constant(nil), noteCardSearchModel: .init())
    }
}