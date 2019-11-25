//
//  ModalTextView.swift
//  FNote
//
//  Created by Dara Beng on 9/15/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI

struct ModalTextView: View {
    
    @Binding var text: String
    
    @Binding var isFirstResponder: Bool
    
    var prompt: String
    
    var onCommit: (() -> Void) = {}
    
    var disableEditing = false
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(prompt)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button(action: onCommit) {
                    Text("Done").bold()
                }
            }
            ModalTextViewWrapper(text: $text, isFirstResponder: $isFirstResponder, disableEditing: disableEditing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .overlay(dragHandle, alignment: .top)
    }
}


extension ModalTextView {
    
    var dragHandle: some View {
        ModalDragHandle(hideOnLandscape: true)
            .padding(.top, 8)
    }
}


struct ModalTextView_Previews: PreviewProvider {
    static var previews: some View {
        ModalTextView(text: .constant("Hello"), isFirstResponder: .constant(true), prompt: "Prompt")
    }
}
