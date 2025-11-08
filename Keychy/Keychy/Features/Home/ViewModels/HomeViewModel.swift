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
    
    // MARK: - Bundle Scene States
    var didPrefetchBundle: Bool = false
    var isBundleLoading: Bool = false
    var isBundleSceneReady: Bool = false
    var bundleScenePreparationDelay: Bool = false
    var allBundleKeyringsStabilized: Bool = false
    
    init(collectionViewModel: CollectionViewModel = CollectionViewModel()) {
        self.collectionViewModel = collectionViewModel
    }
}

