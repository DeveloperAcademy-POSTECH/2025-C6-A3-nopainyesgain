//
//  AlarmView.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI
import FirebaseFirestore

struct AlarmView: View {
    @Bindable var router: NavigationRouter<HomeRoute>

    @State private var viewModel = AlarmViewModel()

    init(router: NavigationRouter<HomeRoute>) {
        self.router = router
    }

    var body: some View {
        ZStack {
            contentArea
            customNavigation
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGesture(enabled: true)
        .onAppear {
            viewModel.checkNotificationPermission()
            viewModel.fetchNotifications()
        }
        .onChange(of: viewModel.notifications) { oldValue, newValue in
            // 알림이 로드되면 이미지 프리페치 시작
            if !newValue.isEmpty {
                viewModel.prefetchNotificationImages()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 설정 앱에서 돌아왔을 때 재체크
            viewModel.checkNotificationPermission()
            viewModel.fetchNotifications()
        }
        .swipeBackGesture(enabled: true)
    }
}

// MARK: - UI Components
extension AlarmView {
    /// 메인 콘텐츠 영역
    private var contentArea: some View {
        ZStack {
            // 알림이 없을 때만 빈 화면 표시
            if viewModel.isNotiEmpty {
                emptyImageView
            }

            // 푸시 알림 off 배너 (최상단)
            VStack(spacing: 0) {
                if viewModel.isNotiOff && viewModel.isNotiOffShown {
                    pushNotiOffView
                }

                // 알림이 있을 때만 리스트 표시
                if !viewModel.isNotiEmpty {
                    notificationListView
                }

                Spacer()
            }
            .adaptiveTopPaddingAlt()
            .padding(.top, 20)
        }
    }

    /// 알림 리스트 뷰
    private var notificationListView: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationItemView(
                    notification: notification,
                    onTap: {
                        handleNotificationTap(notification)
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteNotification(notification)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.top, viewModel.isNotiOff && viewModel.isNotiOffShown ? 8 : 0)
    }

    /// 알림이 없을 때 나오는 뷰
    private var emptyImageView: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(.emptyViewIcon)
            Text("알림함이 비었어요.")
                .typography(.suit15R)
                .padding(15)
        }
    }
    
    /// 기기 푸쉬 알림이 off일 때 나오는 상단뷰
    private var pushNotiOffView: some View {
        Button {
            viewModel.handleNotificationBannerTap()
        } label: {
            HStack(alignment: .center) {
                /// 알람 아이콘
                Image(.alarmIconFill)
                    .padding(.vertical, 3.5)
                    .padding(.trailing, 12)

                /// 알림 off 텍스트
                VStack(alignment: .leading ,spacing: 8) {
                    HStack {
                        Text("기기 알림이 꺼져있어요! 알림을 켜주세요.")
                            .typography(.suit15B25)
                            .foregroundStyle(.black100)
                        Spacer()
                        /// 알림 off 뷰 닫기 버튼
                        Button {
                            withAnimation {
                                viewModel.isNotiOffShown = false
                            }
                        } label: {
                            Image(.dismissGray300)
                        }
                    }
                    Text("눌러서 알림 활성화 하기")
                        .typography(.suit13M)
                        .foregroundStyle(.gray400)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity)
            .background(.gray50)
        }
        .buttonStyle(.plain)
    }
    
    /// 커스텀 네비
    private var customNavigation: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("알림")
        } trailing: {
            Spacer()
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Actions
extension AlarmView {
    /// 알림 탭 처리
    private func handleNotificationTap(_ notification: KeychyNotification) {
        // 1. 읽음 처리
        viewModel.markNotificationAsRead(notification)

        // 2. 선물 완료 화면으로 이동
        router.push(.notificationGiftView(postOfficeId: notification.postOfficeId))
    }
}
