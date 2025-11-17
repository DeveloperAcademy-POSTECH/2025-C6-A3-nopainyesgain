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

    @State private var notificationManager = NotificationManager.shared
    @State private var isNotiEmpty: Bool = true
    @State private var isNotiOff: Bool = false
    @State private var isNotiOffShown: Bool = true

    // 알림 데이터
    @State private var notifications: [KeychyNotification] = []
    @State private var isLoadingNotifications: Bool = false

    // Firebase
    private let db = Firestore.firestore()
    private var userManager = UserManager.shared

    init(router: NavigationRouter<HomeRoute>) {
        self.router = router
    }

    var body: some View {
        ZStack {
            // 알림이 있을 때만 리스트 표시
            if !isNotiEmpty {
                notificationListView
            }

            // 알림이 없을 때만 빈 화면 표시
            if isNotiEmpty {
                emptyImageView
            }

            // 푸시 알림 off 배너 (최상단)
            VStack(spacing: 0) {
                if isNotiOff && isNotiOffShown {
                    pushNotiOffView
                }

                Spacer()
            }
        }
        .padding(.top, 10)
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationPermission()
            fetchNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 설정 앱에서 돌아왔을 때 재체크
            checkNotificationPermission()
            fetchNotifications()
        }
    }
}

extension AlarmView {
    /// 알림 리스트 뷰
    private var notificationListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(notifications) { notification in
                    NotificationItemView(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, isNotiOff && isNotiOffShown ? 8 : 0)
        }
    }

    /// 알림이 없을 때 나오는 뷰
    private var emptyImageView: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("EmptyViewIcon")
            Text("알림함이 비었어요.")
                .typography(.suit15R)
                .padding(15)
        }
    }
    
    /// 기기 푸쉬 알림이 off일 때 나오는 상단뷰
    private var pushNotiOffView: some View {
        Button {
            // 배너 클릭 시 설정 앱으로 이동
            notificationManager.openSettings()
        } label: {
            HStack(alignment: .center) {
                /// 알람 아이콘
                Image("AlarmIconFill")
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
                            Image("dismiss_gray300")
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
    
    /// 알림 권한 체크
    private func checkNotificationPermission() {
        notificationManager.checkPermission { isAuthorized in
            isNotiOff = !isAuthorized  // 권한 없으면 배너 표시
        }
    }

    /// Firestore에서 알림 가져오기
    private func fetchNotifications() {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 찾을 수 없습니다")
            return
        }

        isLoadingNotifications = true

        db.collection("Notifications")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // 최근 50개만 가져오기
            .addSnapshotListener { querySnapshot, error in
                isLoadingNotifications = false

                if let error = error {
                    print("알림 조회 실패: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("알림 문서가 없습니다")
                    notifications = []
                    isNotiEmpty = true
                    return
                }

                // Firestore 문서 → KeychyNotification 모델 변환
                notifications = documents.compactMap { document in
                    KeychyNotification(documentId: document.documentID, data: document.data())
                }

                // 빈 상태 업데이트
                isNotiEmpty = notifications.isEmpty

                print("알림 \(notifications.count)개 로드됨")
            }
    }

    /// 알림 탭 처리
    private func handleNotificationTap(_ notification: KeychyNotification) {
        // 1. 읽음 처리
        markNotificationAsRead(notification)

        // 2. 선물 완료 화면으로 이동
        router.push(.notificationGiftView(postOfficeId: notification.postOfficeId))
    }

    /// 알림을 읽음 처리
    private func markNotificationAsRead(_ notification: KeychyNotification) {
        guard let notificationId = notification.documentId else {
            print("알림 문서 ID가 없습니다")
            return
        }

        // 이미 읽음 상태면 스킵
        if notification.isRead {
            return
        }

        db.collection("Notifications")
            .document(notificationId)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("알림 읽음 처리 실패: \(error.localizedDescription)")
                } else {
                    print("알림 읽음 처리 완료: \(notificationId)")
                }
            }
    }
}
