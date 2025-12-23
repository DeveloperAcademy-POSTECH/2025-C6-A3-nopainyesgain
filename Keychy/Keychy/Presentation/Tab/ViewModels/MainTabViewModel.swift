//
//  MainTabViewModel.swift
//  Keychy
//
//  Created on 12/23/24.
//

import SwiftUI

/// MainTabView의 상태 및 비즈니스 로직 관리
@Observable
class MainTabViewModel {
    // MARK: - Constants
    enum TabIndex: Int {
        case home = 0
        case workshop = 1
        case collection = 2
        case festival = 3
    }

    enum Delay {
        static let splashAnimation: TimeInterval = 0.3
        static let deepLinkCheck: TimeInterval = 0.1
        static let deepLinkChange: TimeInterval = 0.2
        static let sheetPresentation: TimeInterval = 0.5
        static let tabSwitchAnimation: TimeInterval = 0.3
    }

    // MARK: - Properties
    // 탭 관련
    var selectedTab = TabIndex.home.rawValue

    // 라우터들
    var homeRouter = NavigationRouter<HomeRoute>()
    var collectionRouter = NavigationRouter<CollectionRoute>()
    var workshopRouter = NavigationRouter<WorkshopRoute>()
    var festivalRouter = NavigationRouter<FestivalRoute>()

    // Sheet 관련
    var showReceiveSheet = false
    var showCollectSheet = false
    var receivedPostOfficeId: String?
    var collectedPostOfficeId: String?
    var shouldRefreshCollection = false

    // 스플래시
    var showSplash = true

    // 다른 ViewModel들
    let collectionViewModel = CollectionViewModel()
    let festivalViewModel = Showcase25BoardViewModel()

    // 매니저들
    private let userManager = UserManager.shared
    private let deepLinkManager = DeepLinkManager.shared

    // MARK: - Computed Properties
    var userManagerInstance: UserManager {
        userManager
    }

    var deepLinkManagerInstance: DeepLinkManager {
        deepLinkManager
    }

    // MARK: - Lifecycle Methods
    func handleAppear() {
        // 앱 진입 시 배지 카운트 동기화
        userManager.updateBadgeCount()

        DispatchQueue.main.asyncAfter(deadline: .now() + Delay.deepLinkCheck) {
            self.checkPendingDeepLink()
        }
    }

    func handleDeepLinkChange(oldValue: String?, newValue: String?) {
        if newValue != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.deepLinkChange) {
                self.checkPendingDeepLink()
            }
        }
    }

    func updateBadgeCount() {
        userManager.updateBadgeCount()
    }

    // MARK: - Action Handlers
    func handleSwitchToWorkshop(_ route: WorkshopRoute) {
        // Festival에서 Workshop으로 갈 때 플래그 설정
        festivalViewModel.isFromFestivalTab = true
        festivalViewModel.onKeyringCompleteFromFestival = { [weak self] router in
            guard let self = self else { return }
            // 키링 완료 후 Workshop navigation stack 초기화
            router.reset()

            // Festival 탭으로 복귀
            self.selectedTab = TabIndex.festival.rawValue

            // 플래그 초기화
            self.festivalViewModel.isFromFestivalTab = false
        }

        // 탭을 공방으로 전환
        selectedTab = TabIndex.workshop.rawValue
        // 약간의 딜레이 후 라우팅 (탭 전환 애니메이션 완료 대기)
        DispatchQueue.main.asyncAfter(deadline: .now() + Delay.tabSwitchAnimation) {
            self.workshopRouter.push(route)
        }
    }

    func handleReceiveDismiss() {
        if receivedPostOfficeId != nil {
            shouldRefreshCollection = true
        }
        receivedPostOfficeId = nil
    }

    func handleCollectDismiss() {
        if collectedPostOfficeId != nil {
            shouldRefreshCollection = true
        }
        collectedPostOfficeId = nil
    }

    // MARK: - DeepLink Handling
    func checkPendingDeepLink() {
        if let (postOfficeId, type) = deepLinkManager.consumePendingDeepLink() {
            handleDeepLink(postOfficeId: postOfficeId, type: type)
        }
    }

    func handleDeepLink(postOfficeId: String, type: DeepLinkType) {
        switch type {
        case .receive:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: true)
        case .collect:
            handleSheetDeepLink(postOfficeId: postOfficeId, isReceive: false)
        case .notification:
            selectedTab = TabIndex.home.rawValue
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.sheetPresentation) {
                self.homeRouter.push(.notificationGiftView(postOfficeId: postOfficeId))
            }
        }
    }

    private func handleSheetDeepLink(postOfficeId: String, isReceive: Bool) {
        selectedTab = TabIndex.collection.rawValue

        if isReceive {
            receivedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.sheetPresentation) {
                self.showReceiveSheet = true
            }
        } else {
            collectedPostOfficeId = postOfficeId
            DispatchQueue.main.asyncAfter(deadline: .now() + Delay.sheetPresentation) {
                self.showCollectSheet = true
            }
        }
    }
}
