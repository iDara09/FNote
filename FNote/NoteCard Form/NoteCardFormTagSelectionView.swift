//
//  NoteCardFormTagSelectionView.swift
//  FNote
//
//  Created by Dara Beng on 1/22/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import SwiftUI


struct NoteCardFormTagSelectionView: View {
        
    var viewModel: TagCollectionViewModel
    
    var onCreateTag: ((String) -> Bool)?
    
    @State private var textFieldModel = ModalTextFieldModel()
    @State private var showCreateTagSheet = false
    
    
    var body: some View {
        CollectionViewWrapper(viewModel: viewModel)
            .navigationBarTitle("Tags")
            .navigationBarItems(trailing: createTagNavItem)
            .sheet(isPresented: $showCreateTagSheet, content: createTagSheet)
    }
}


// MARK: - Create Tag

extension NoteCardFormTagSelectionView {
    
    var createTagNavItem: some View {
        NavigationBarButton(imageName: "plus", action: beginCreateTag)
            .disabled(onCreateTag == nil)
    }
    
    func createTagSheet() -> some View {
        ModalTextField(viewModel: $textFieldModel)
    }
    
    func beginCreateTag() {
        textFieldModel = .init()
        textFieldModel.title = "New Tag"
        textFieldModel.text = ""
        textFieldModel.placeholder = "Tag Name"
        textFieldModel.onCommit = commitCreateTag
        textFieldModel.isFirstResponder = true
        showCreateTagSheet = true
    }
    
    func commitCreateTag() {
        let name = textFieldModel.text.trimmed()
        
        if name.isEmpty {
            showCreateTagSheet = false
            return
        }
        
        if onCreateTag?(name) == true {
            showCreateTagSheet = false
        } else {
            textFieldModel.prompt = "Duplicate tag name!"
            textFieldModel.promptColor = .red
        }
    }
}


struct NoteCardFormTagSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardFormTagSelectionView(viewModel: .init())
    }
}
