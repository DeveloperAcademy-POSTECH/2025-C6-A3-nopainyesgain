//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct HomeTab: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @Bindable var userManager: UserManager
    @State private var collectionViewModel = CollectionViewModel()
    @Bindable private var introViewModel = IntroViewModel()

    /// 배경 로드 완료 콜백
    var onBackgroundLoaded: (() -> Void)? = nil

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(
                router: router,
                userManager: userManager,
                collectionViewModel: collectionViewModel,
                onBackgroundLoaded: onBackgroundLoaded
            )
                .navigationDestination(for: HomeRoute.self) {route in
                    switch route {
                        //키링 뭉치함
                    case .bundleInventoryView:
                        BundleInventoryView(router: router, viewModel: collectionViewModel)
                    case .bundleDetailView:
                        BundleDetailView(router: router, viewModel: collectionViewModel)
                    case .bundleSelectCarabinerView:
                        BundleSelectCarabinerView(router: router, viewModel: collectionViewModel)
                    case .bundleAddKeyringView:
                        BundleAddKeyringView(router: router, viewModel: collectionViewModel)
                    case .bundleNameInputView:
                        BundleNameInputView(router: router, viewModel: collectionViewModel)
                    case .bundleNameEditView:
                        BundleNameEditView(router: router, viewModel: collectionViewModel)
                    case .bundleEditView:
                        BundleEditView(router: router, viewModel: collectionViewModel)
                        // 재화 충전
                    case .coinCharge:
                        CoinChargeView(router: router)
                    case .myPageView:
                        MyPageView(router: router)
                    case .changeName:
                        ChangeNameView(router: router)
                    case .alarmView:
                        AlarmView()
                    case .introView:
                        IntroView(viewModel: introViewModel)
                    case .termsAndPolicy:
                        TermsView(router: router)
                }
            }
        }
    }
}
