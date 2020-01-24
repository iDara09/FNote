//
//  NoteCardView.swift
//  FNote
//
//  Created by Veronica Sumariyanto on 9/9/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI

struct NoteCardView: View {
    
    @EnvironmentObject var noteCardDataSource: NoteCardDataSource
    
    @ObservedObject var noteCard: NoteCard
    
    var showQuickButtons: Bool = true
    
    var showSelection = false
    
    @ObservedObject private var viewReloader = ViewForceReloader()
    
    @State private var sheet: Sheet?
    
    /// A flag to control note model text field keyboard.
    @State private var isNoteEditingActive = false

    @State private var relationshipNoteCards = [NoteCard]()
    
    
    // MARK: Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack{
                Text(noteCard.native)
                    .font(.title)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if showQuickButtons && !noteCard.note.isEmpty {
                    Spacer()
                    noteButton
                }
            }
            
            Divider()
                .background(Color.noteCardDivider)
            
            Text(noteCard.translation)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if showQuickButtons {
                HStack (alignment: .center) {
                    relationshipButton
                    Spacer()
                    tagButton
                    Spacer()
                    formalButton
                    Spacer()
                    starButton
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.noteCardBackground)
        .cornerRadius(15)
        .overlay(selectionBorder)
        .shadow(color: Color.primary.opacity(0.1), radius: 1, x: -1, y: 1)
        .sheet(item: $sheet, onDismiss: dismissSheet, content: previewSheet)
    }
}


extension NoteCardView {
    
    var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(Color.appAccent, lineWidth: 2)
            .opacity(showSelection ? 1 : 0)
    }
    
    var relationshipButton: some View {
        Button(action: beginPreviewRelationships) {
            HStack {
                Image.noteCardRelationship
                Text("\(noteCard.relationships.count)")
                    .font(.body)
            }
            .foregroundColor(.primary)
        }
    }
    
    var tagButton: some View {
        Button(action: beginPreviewTags) {
            HStack {
                Image.noteCardTag
                Text("\(noteCard.tags.count)")
            }
            .font(.body)
            .foregroundColor(.primary)
        }
    }
    
    var formalButton: some View {
        Button(action: {}) {
            HStack {
                Image.noteCardFormality
                Text(noteCard.formality.abbreviation)
            }
            .font(.body)
            .foregroundColor(noteCard.formality.color)
        }
    }
    
    var starButton: some View {
        Button(action: toggleNoteCardFavorite) {
            Image.noteCardFavorite(noteCard.isFavorited)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    var noteButton: some View {
        Button(action: beginPreviewNote) {
            ZStack(alignment: .trailing) {
                Rectangle() // invisible view for more tappable area
                    .fill(Color.clear)
                    .frame(width: 35, height: 35, alignment: .center)
                Image.noteCardNote
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }
    
    func toggleNoteCardFavorite() {
        noteCard.isFavorited.toggle()
        noteCard.managedObjectContext?.quickSave()
        noteCard.managedObjectContext?.parent?.quickSave()
        viewReloader.forceReload()
    }
}


// MARK: - Relationships Preview Sheet

extension NoteCardView {
    
    /// A sheet that previews the related cards of the selected card.
    var relationshipPreviewsSheet: some View {
        let doneNavItem = Button("Done", action: donePreviewRelationships)
        return NavigationView {
            NoteCardScrollView(
                noteCards: relationshipNoteCards,
                showQuickButtons: false,
                searchContext: noteCard.managedObjectContext,
                onTap: requestDisplayingNoteCard
            )
                .navigationBarTitle("Links", displayMode: .inline)
                .navigationBarItems(leading: doneNavItem)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Action that goes in the quick button
    func beginPreviewRelationships() {
        relationshipNoteCards = noteCard.relationships.sorted(by: { $0.translation < $1.translation })
        sheet = .relationship
    }
    
    func donePreviewRelationships() {
        relationshipNoteCards = []
        sheet = nil
    }
    
    func requestDisplayingNoteCard(_ noteCard: NoteCard) {
        donePreviewRelationships()
        NotificationCenter.default.post(name: .requestDisplayingNoteCard, object: noteCard)
    }
}


// MARK: - Tag Preview Sheet

extension NoteCardView {
    
    /// A sheet that previews the tags of the selected card.
    var tagPreviewSheet: some View {
        let doneNavItem = Button("Done", action: donePreviewNote)
        let tags = noteCard.tags.sorted(by: { $0.name < $1.name })
        return NavigationView {
            List {
                ForEach(tags, id: \.uuid) { tag in
                    Text(tag.name)
                        .foregroundColor(.primary)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Tags", displayMode: .inline)
            .navigationBarItems(leading: doneNavItem)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Action that goes in the quick button
    func beginPreviewTags() {
        sheet = .tag
    }
    
    func donePreviewTags() {
        sheet = nil
    }
}


// MARK: - Note Preview Sheet

extension NoteCardView {
    
    /// A sheet that previews note of the selected card.
    var notePreviewSheet: some View {
        ModalTextView(viewModel: .constant(.init()))
//        ModalTextView(
//            title: "Notes",
//            text: $noteCard.note,
//            isFirstResponder: $isNoteEditingActive,
//            onDone: donePreviewNote,
//            disableEditing: true,
//            renderMarkdown: true
//        )
    }
    
    // Action that goes in the quick button
    func beginPreviewNote() {
        sheet = .note
    }
    
    func donePreviewNote() {
        sheet = nil
    }
}


// MARK: - Sheets

extension NoteCardView {
    
    enum Sheet: Identifiable {
        case relationship
        case tag
        case note
        
        var id: Sheet { self }
    }
    
    func previewSheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .relationship:
            return relationshipPreviewsSheet.eraseToAnyView()
        case .tag:
            return tagPreviewSheet.eraseToAnyView()
        case .note:
            return notePreviewSheet.eraseToAnyView()
        }
    }
    
    var dismissSheet: () -> Void {
        switch sheet {
        case .relationship:
            return donePreviewRelationships
        case .tag:
            return donePreviewTags
        case .note:
            return donePreviewNote
        case nil:
            return {}
        }
    }
}



struct NoteCardCollectionViewCard_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardView(noteCard: .init())
    }
}