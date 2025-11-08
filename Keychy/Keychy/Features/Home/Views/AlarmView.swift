//
//  AlarmView.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI

struct AlarmView: View {

    @State private var notificationManager = NotificationManager.shared
    @State private var isNotiEmpty: Bool = false
    @State private var isNotiOff: Bool = false
    @State private var isNotiOffShown: Bool = true

    var body: some View {
        ZStack {
            emptyImageView
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
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 설정 앱에서 돌아왔을 때 재체크
            checkNotificationPermission()
        }
    }
}

extension AlarmView {
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
}
