//
//  ModalTextFieldWrapper.swift
//  FNote
//
//  Created by Dara Beng on 9/13/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


struct ModalTextFieldWrapper: UIViewRepresentable {
    
    @Binding var isActive: Bool
    
    @Binding var text: String
    
    var placeholder: String
    
    var onCommit: (() -> Void)?
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        let coordinator = context.coordinator
        
        coordinator.onCommit = onCommit
        coordinator.configureTargetAndDelegate(for: textField)
        
        textField.font = .preferredFont(forTextStyle: .largeTitle)
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
        
        let coordinator = context.coordinator
        coordinator.isActive = isActive
        coordinator.handleFirstResponder(for: uiView)
    }
    
    
    // MARK: Coordiantor
    
    class Coordinator: NSObject, UITextFieldDelegate {
        
        @Binding var text: String
        
        var isActive = false
                
        var onCommit: (() -> Void)?
        
        private var canBecomeFirstResponder = false
        
        
        init(text: Binding<String>) {
            _text = text
        }
    
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onCommit?()
            textField.resignFirstResponder()
            canBecomeFirstResponder = true
            return true
        }
        
        func handleFirstResponder(for textField: UITextField) {
            let textFieldWillAppear = textField.window == nil
            let textFieldDidAppear = textField.window != nil
            
            if textFieldWillAppear {
                canBecomeFirstResponder = true
            }
            
            guard isActive, canBecomeFirstResponder, textFieldDidAppear, !textField.isFirstResponder else { return }
            textField.becomeFirstResponder()
            canBecomeFirstResponder = false
        }
        
        func configureTargetAndDelegate(for textField: UITextField) {
            textField.delegate = self
            textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        }
        
        @objc private func handleEditingChanged(_ sender: UITextField) {
            text = sender.text!
        }
    }
}
