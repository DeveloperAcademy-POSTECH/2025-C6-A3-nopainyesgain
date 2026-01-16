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
    @State private var bundleViewModel = BundleViewModel()
    @Binding var shouldRefresh: Bool
    
    var body: some View {
        NavigationStack(path: $router.path) {
            CollectionView(router: router, collectionViewModel: collectionViewModel, shouldRefresh: $shouldRefresh)
                .navigationDestination(for: CollectionRoute.self) { route in
                    switch route {
                        
                    case .collectionKeyringDetailView(let keyring, let isSearchMode):
                        CollectionKeyringDetailView(router: router, viewModel: collectionViewModel, isSearchMode: isSearchMode, keyring: keyring)
                    case .collectionKeyringPackageView(let keyring, let isSearchMode):
                        CollectionKeyringPackageView(router: router, viewModel: collectionViewModel, isSearchMode: isSearchMode, keyring: keyring)
                    case .keyringEditView(let keyring):
                        KeyringEditView(router: router, viewModel: collectionViewModel, keyring: keyring)
                    case .bundleInventoryView:
                        BundleInventoryView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleDetailView:
                        BundleDetailView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleCreateView:
                        BundleCreateView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleAddKeyringView:
                        BundleAddKeyringView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleNameInputView:
                        BundleNameInputView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleNameEditView:
                        BundleNameEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
                    case .bundleEditView:
                        BundleEditView(router: router, collectionVM: collectionViewModel, bundleVM: bundleViewModel)
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
