//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct CollectionTab: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    
    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionView(router: router, collectionViewModel: CollectionViewModel())
                .navigationDestination(for: CollectionRoute.self) { route in
                    switch route {
                        
                    case .collectionKeyringDetailView:
                        CollectionKeyringDetailView()
                    }
                }
        }
    }
}
