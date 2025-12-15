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
    @State private var notificationManager = NotificationManager.shared
    @State private var isNotiOff: Bool = false
    @State private var isNotiOffShown: Bool = true
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init(router: NavigationRouter<HomeRoute>) {
        self.router = router
    }

    var body: some View {
        ZStack {
            // 알림이 없을 때만 빈 화면 표시
            if viewModel.isNotiEmpty {
                emptyImageView
            }

            // 푸시 알림 off 배너 (최상단)
            VStack(spacing: 0) {
                if isNotiOff && isNotiOffShown {
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

            customNavigation
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGesture(enabled: true)
        .onAppear {
            checkNotificationPermission()
            viewModel.fetchNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 설정 앱에서 돌아왔을 때 재체크
            checkNotificationPermission()
            viewModel.fetchNotifications()
        }
        .swipeBackGesture(enabled: true)
    }
}

extension AlarmView {
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
        .padding(.top, isNotiOff && isNotiOffShown ? 8 : 0)
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
            handleNotificationBannerTap()
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
                                isNotiOffShown = false
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
    
    /// 알림 권한 체크
    private func checkNotificationPermission() {
        notificationManager.getAuthorizationStatus { status in
            authorizationStatus = status
            // authorized가 아니면 배너 표시 (notDetermined, denied 모두 포함)
            isNotiOff = (status != .authorized)
        }
    }

    /// 알림 배너 탭 처리
    private func handleNotificationBannerTap() {
        if authorizationStatus == .notDetermined {
            // 아직 권한 요청 안한 경우 → 권한 요청 팝업 표시
            notificationManager.requestPermission { granted in
                // 권한 요청 후 다시 체크
                checkNotificationPermission()
            }
        } else {
            // 이미 거부된 경우 → 설정 앱으로 이동
            notificationManager.openSettings()
        }
    }

    /// 알림 탭 처리
    private func handleNotificationTap(_ notification: KeychyNotification) {
        // 1. 읽음 처리
        viewModel.markNotificationAsRead(notification)

        // 2. 선물 완료 화면으로 이동
        router.push(.notificationGiftView(postOfficeId: notification.postOfficeId))
    }
}
