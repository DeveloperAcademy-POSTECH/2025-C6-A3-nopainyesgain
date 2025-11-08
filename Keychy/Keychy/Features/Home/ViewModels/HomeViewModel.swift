//
//  HomeViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import SwiftUI
import Foundation

@Observable
class HomeViewModel {
    // MARK: - Collection ViewModel
    var collectionViewModel: CollectionViewModel
    
    init(collectionViewModel: CollectionViewModel = CollectionViewModel()) {
        self.collectionViewModel = collectionViewModel
    }
}

