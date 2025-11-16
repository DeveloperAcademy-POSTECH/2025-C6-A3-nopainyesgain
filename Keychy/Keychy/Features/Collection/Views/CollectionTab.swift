//
//  CollectionTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct CollectionTab: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @State private var collectionViewModel = CollectionViewModel()
    @Binding var shouldRefresh: Bool
    
    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionView(router: router, collectionViewModel: collectionViewModel, shouldRefresh: $shouldRefresh)
                .navigationDestination(for: CollectionRoute.self) { route in
                    switch route {
                        
                    case .collectionKeyringDetailView(let keyring):
                        CollectionKeyringDetailView(router: router, viewModel: collectionViewModel, keyring: keyring)
                    case .collectionKeyringPackageView(let keyring):
                        CollectionKeyringPackageView(router: router, viewModel: collectionViewModel, keyring: keyring)
                    case .keyringEditView(let keyring):
                        KeyringEditView(router: router, viewModel: collectionViewModel, keyring: keyring)
                    case .bundleInventoryView:
                        EmptyView()
                    case .widgetSettingView:
                        WidgetSettingView(router: router)
                    case .packageCompleteView(let keyring, let postOfficeId):
                        PackageCompleteView(router: router, viewModel: collectionViewModel, keyring: keyring, postOfficeId: postOfficeId)
                        
                    case .coinCharge:
                        CoinChargeView(router: router)
                    }
                }
        }
        .tint(.black)
    }
}
