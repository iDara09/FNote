//
//  NoteCardView.swift
//  FNote
//
//  Created by Dara Beng on 9/11/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


struct NoteCardView: View {
    
    @EnvironmentObject var noteCardDataSource: NoteCardDataSource
    
    @EnvironmentObject var tagDataSource: TagDataSource
    
    @ObservedObject var noteCard: NoteCard
    
    /// An action to perform when delete button is tapped.
    ///
    /// The delete button is hidden if this value is `nil`.
    var onDelete: (() -> Void)?
    
    /// A flag to control note model text field keyboard.
    @State private var isNoteEditingActive = true
    
    /// A sheet to indicate when presentation sheet to show.
    @State private var sheet: Sheet?
    
    @State private var showDeleteAlert = false
    
    let imageSize: CGFloat = 20
    
    
    // MARK: Body
    
    var body: some View {
        Form {
            Section(header: Text("NATIVE & TRANSLATION").padding(.top, 20)) {
                // MARK: Native & Translation
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Native", text: $noteCard.native)
                        .font(.title)
                    Text("Native")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Translation", text: $noteCard.translation)
                        .font(.title)
                    Text("Translation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("RELATIONSHIP & TAG")) {
                // MARK: Formality
                HStack {
                    Image.noteCardFormality
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                        .foregroundColor(noteCard.formality.color)
                    Picker("Formality", selection: $noteCard.formality) {
                        ForEach(NoteCard.Formality.allCases, id: \.self) { formality in
                            Text(formality.title).tag(formality)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // MARK: Favorite
                Toggle(isOn: $noteCard.isFavorited) {
                    Image.noteCardFavorite(noteCard.isFavorited)
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                    Text("Favorite")
                }
                
                // MARK: Relationship
                Button(action: beginEditingRelationship) {
                    HStack {
                        Image.noteCardRelationship
                            .frame(width: imageSize, height: imageSize, alignment: .center)
                        Text("Relationship")
                    }
                    .foregroundColor(.primary)
                }
                
                // MARK: Tag
                Button(action: beginEditingTag) {
                    HStack {
                        Image.noteCardTag
                            .frame(width: imageSize, height: imageSize, alignment: .center)
                        Text("Tags")
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Section(header: Text("NOTE")) {
                // MARK: Note
                NoteCardNoteTextViewWrapper(text: $noteCard.note)
                    .frame(minHeight: 250, maxHeight: .infinity, alignment: .center)
                    .padding(0)
                    .overlay(emptyNotePlaceholderText, alignment: .topLeading)
                    .onTapGesture(perform: beginEditingNote)
            }
            
            Section {
                // MARK: Delete
                Button(action: { self.showDeleteAlert = true }) {
                    Text("Delete")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .hidden(onDelete == nil)
            }
        }
        .sheet(item: $sheet, onDismiss: dismissSheet, content: presentationSheet)
        .alert(isPresented: $showDeleteAlert, content: deleteAlert)
    }
}


// MARK: - Relationship Sheet

extension NoteCardView {
    
    // View that uses the NoteCardRelationshipView
    var relationshipEditingSheet: some View {
        NoteCardRelationshipView(noteCard: noteCard, onDone: doneEditingRelationship)
            .environmentObject(noteCardDataSource)
    }
    
    func beginEditingRelationship() {
        sheet = .relationship
    }
    
    func doneEditingRelationship() {
        sheet = nil
    }
}


// MARK: - Tag Sheet

extension NoteCardView {
    
    var tagEditingSheet: some View {
        NoteCardTagView(noteCard: noteCard, onDone: doneEditingTag)
    }
    
    func beginEditingTag() {
        sheet = .tag
    }
    
    func doneEditingTag() {
        sheet = nil
    }
}


// MARK: - Note Sheet

extension NoteCardView {
    
    var noteEditingSheet: some View {
        ModalTextView(
            isActive: $isNoteEditingActive,
            text: $noteCard.note,
            prompt: "Note",
            onCommit: commitEditingNote
        )
    }
    
    var emptyNotePlaceholderText: some View {
        Text(noteCard.note.isEmpty ? ". . ." : "")
            .font(.body)
            .padding(6)
            .foregroundColor(.secondary)
    }
    
    func rowImage(systemName: String) -> some View {
        Image(systemName: systemName)
            .frame(minWidth: 20, maxWidth: 20, alignment: .center)
    }
    
    func beginEditingNote() {
        sheet = .note
    }
    
    func commitEditingNote() {
        noteCard.note = noteCard.note.trimmed()
        sheet = nil
    }
}


// MARK: - Presentation Sheet

extension NoteCardView {
    
    enum Sheet: Identifiable {
        case relationship
        case tag
        case note
        
        var id: Sheet { self }
    }
    
    func presentationSheet(for sheet: Sheet) -> some View {
        switch sheet {
        
        case .relationship:
            return relationshipEditingSheet
                .eraseToAnyView()
        
        case .tag:
            return tagEditingSheet
                .environmentObject(tagDataSource)
                .eraseToAnyView()
        
        case .note:
            return noteEditingSheet
                .eraseToAnyView()
        }
    }
    
    var dismissSheet: () -> Void {
        switch sheet {
        case .relationship:
            return doneEditingRelationship
        case .tag:
            return doneEditingTag
        case .note:
            return commitEditingNote
        case nil:
            return {}
        }
    }
}


// MARK: - Alert

extension NoteCardView {
    
    func deleteAlert() -> Alert {
        let title = Text("Delete Note Card")
        let message = Text("Delete note card from the collection.")
        let delete = Alert.Button.destructive(Text("Delete"), action: onDelete)
        return Alert(title: title, message: message, primaryButton: .cancel(), secondaryButton: delete)
    }
}


struct NoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardView(noteCard: .init())
    }
}
