//
//  NoteCardCollectionViewModel.swift
//  FNote
//
//  Created by Dara Beng on 1/19/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import UIKit


class NoteCardCollectionViewModel: NSObject {
    
    typealias DataSourceSection = Int
    
    typealias DataSourceItem = NoteCard
    
    
    // MARK: Property
    
    var noteCards: [NoteCard] = []
    
    var dataSource: DiffableDataSource!
    
    
    // MARK: Action
    
    var onNoteCardSelected: ((NoteCard) -> Void)?
    var onNoteCardQuickButtonTapped: ((NoteCardCell.QuickButtonType, NoteCard) -> Void)?
    
    private let cellID = "NoteCardCellID"
    
    
    func updateSnapshot(with noteCards: [NoteCard]? = nil, animated: Bool, completion: (() -> Void)? = nil) {
        if let noteCards = noteCards {
            self.noteCards = noteCards
        }
        
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(self.noteCards, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: animated, completion: completion)
    }
}


// MARK: - Collection Delegate

extension NoteCardCollectionViewModel: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let noteCard = dataSource.itemIdentifier(for: indexPath) else { return }
        onNoteCardSelected?(noteCard)
    }
}


// MARK: - Collection Diff Data Source

extension NoteCardCollectionViewModel: CollectionViewCompositionalDataSource {
    
    func setupCollectionView(_ collectionView: UICollectionView) {
        collectionView.collectionViewLayout = createCompositionalLayout()
        collectionView.register(NoteCardCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.delegate = self
        
        collectionView.alwaysBounceVertical = true
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, noteCard in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellID, for: indexPath) as! NoteCardCell
            cell.reload(with: noteCard)
            cell.onQuickButtonTapped = self.onNoteCardQuickButtonTapped
            return cell
        }
    }
    
    func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment in
            self.createLayoutSection()
        }
        return layout
    }
    
    func createLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let height = NoteCardCell.Style.regular.height
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        
        return section
    }
}
