//
//  NoteCardSearchScope.swift
//  FNote
//
//  Created by Dara Beng on 10/29/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import Foundation


enum NoteCardSearchField: String {
    case translation
    case native
    case note
    
    var keyPath: String {
        switch self {
        case .translation: return #keyPath(NoteCard.translation)
        case .native: return #keyPath(NoteCard.native)
        case .note: return #keyPath(NoteCard.note)
        }
    }
}


enum NoteCardSortField: Int {
    case native
    case translation
    
    var trayItemTitle: String {
        switch self {
        case .native: return "By Native"
        case .translation: return "By Translation"
        }
    }
}