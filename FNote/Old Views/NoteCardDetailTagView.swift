//
//  NoteCardDetailTagView.swift
//  FNote
//
//  Created by Dara Beng on 9/27/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


struct NoteCardDetailTagView: View {
    
    @EnvironmentObject var tagDataSource: TagDataSource
    
    @ObservedObject var noteCard: NoteCard
    
    /// A text for the sheet view.
    @State private var modalTextFieldText = ""
    
    /// A placeholder string for the sheet view.
    @State private var modalTextFieldPlaceholder = ""
    
    /// A prompt string for the sheet view.
    @State private var modalTextFieldPrompt = ""
    
    /// A description used to describe error.
    @State private var modalTextFieldDescription = ""
    
    /// A flag used to present or dismiss the rename or create sheet.
    @State private var showModalTextField = false
    
    /// A flag used to handle modal text field keyboard.
    @State private var isModalTextFieldActive = false
    
    /// An action to perform when the done button is tapped.
    var onDone: (() -> Void)?
    
    var includedTags: [Tag] {
        tagDataSource.fetchedObjects.filter { tag in
            self.noteCard.tags.contains(where: { $0.uuid == tag.uuid })
        }
    }
    
    var excludedTags: [Tag] {
        tagDataSource.fetchedObjects.filter { tag in
            !self.noteCard.tags.contains(where: { $0.uuid == tag.uuid })
        }
    }
    
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("SELECTED TAGS").padding(.top, 20)) {
                    if noteCard.tags.isEmpty {
                        Text("none")
                        .foregroundColor(.secondary)
                    } else {
                        ForEach(includedTags, id: \.uuid) { tag in
                            self.tagRow(for: tag)
                        }
                    }
                }
                
                Section(header: Text("TAGS")) {
                    if excludedTags.isEmpty {
                        Text("none").foregroundColor(.secondary)
                    } else {
                        ForEach(excludedTags, id: \.uuid) { tag in
                            self.tagRow(for: tag)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Tags", displayMode: .inline)
            .navigationBarItems(leading: doneNavItem, trailing: createNewTagNavItem)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showModalTextField, onDismiss: dismissModalTextField, content: modalTextField)
    }
}


extension NoteCardDetailTagView {
    
    func tagRow(for tag: Tag) -> some View {
        Button(action: { self.tagRowSelected(tag) }) {
            Text(tag.name)
                .accentColor(.primary)
        }
    }
    
    func tagRowSelected(_ tag: Tag) {
        if let tag = noteCard.tags.first(where: { $0.uuid == tag.uuid }) {
            noteCard.tags.remove(tag)
        
        } else if let tag = tagDataSource.fetchedObjects.first(where: { $0.uuid == tag.uuid }) {
            let tagToAdd = tag.get(from: noteCard.managedObjectContext!)
            noteCard.tags.insert(tagToAdd)
        }
    }
}


extension NoteCardDetailTagView {
    
    var createNewTagNavItem: some View {
        Button(action: beginCreateNewTag) {
            Image(systemName: "plus")
                .imageScale(.large)
        }
        .buttonStyle(NavigationItemIconStyle())
    }
    
    var doneNavItem: some View {
        Button("Done", action: onDone ?? {})
            .opacity(onDone == nil ? 0 : 1)
    }
    
    func modalTextField() -> some View {
        ModalTextField(viewModel: .constant(.init()))
    }
    
    func beginCreateNewTag() {
        modalTextFieldPrompt = "New Tag"
        modalTextFieldPlaceholder = "Tag Name"
        modalTextFieldText = ""
        modalTextFieldDescription = ""
        isModalTextFieldActive = true
        showModalTextField = true
    }
    
    func cancelCreateNewTag() {
        isModalTextFieldActive = false
        showModalTextField = false
    }
    
    func commitCreateNewTag() {
        let tagName = modalTextFieldText.trimmed()
        
        // if tag exists, show cannot create message
        if Tag.isNameExisted(name: tagName, in: tagDataSource.createContext) {
            modalTextFieldDescription = "Tag name '\(tagName)' already exists"
            return
        }
        
        // create if it is not an empty whitespaces
        if !tagName.isEmptyOrWhiteSpaces() {
            tagDataSource.prepareNewObject()
            
            let newTag = tagDataSource.newObject!
            newTag.name = tagName
            tagDataSource.saveCreateContext()
            
            let newTagToAdd = newTag.get(from: noteCard.managedObjectContext!)
            noteCard.tags.insert(newTagToAdd)
            
            tagDataSource.discardNewObject()
        }
        
        isModalTextFieldActive = false
        dismissModalTextField()
    }
    
    func dismissModalTextField() {
        showModalTextField = false
    }
}


struct NoteCardTagView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardDetailTagView(noteCard: .init())
    }
}