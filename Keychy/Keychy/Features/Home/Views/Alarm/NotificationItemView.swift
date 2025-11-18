//
//  NotificationItemView.swift
//  Keychy
//
//  Created on 11/18/25.
//

import SwiftUI

/// 알림 아이템 컴포넌트
/// - 선물 수락 알림을 표시
/// - 미확인: MainOpacity15 배경, 확인: white 배경
struct NotificationItemView: View {
    let notification: KeychyNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 선물 아이콘
                Image("giftAccepted")

                // 알림 내용
                VStack(alignment: .leading, spacing: 0) {
                    
                    HStack(spacing: 0) {
                        Text(notification.senderNickname)
                            .typography(.notosans14SB)
                            .foregroundStyle(.black100)
                        Text(notification.message)
                            .typography(.suit15R)
                            .foregroundStyle(.black100)
                            .padding(.top, 3)
                            
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 시간
                    Text(notification.relativeTimeString)
                        .typography(.suit15R)
                        .foregroundStyle(.gray300)
                }
                

                //Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(notification.isRead ? .white100 : .mainOpacity15)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("미확인 알림") {
    NotificationItemView(
        notification: KeychyNotification(
            type: .giftAccepted,
            receiverId: "user123",
            senderId: "user456",
            senderNickname: "sing",
            keyringName: "귀여운 키링",
            postOfficeId: "post123",
            isRead: false,
            createdAt: Date().addingTimeInterval(-300) // 5분 전
        ),
        onTap: {
            print("알림 탭됨")
        }
    )
    .padding()
}

#Preview("확인한 알림") {
    NotificationItemView(
        notification: KeychyNotification(
            type: .giftAccepted,
            receiverId: "user123",
            senderId: "user456",
            senderNickname: "홍길동",
            keyringName: "내 첫 키링",
            postOfficeId: "post456",
            isRead: true,
            createdAt: Date().addingTimeInterval(-7200) // 2시간 전
        ),
        onTap: {
            print("알림 탭됨")
        }
    )
    .padding()
}

#Preview("알림 리스트") {
    ScrollView {
        VStack(spacing: 8) {
            NotificationItemView(
                notification: KeychyNotification(
                    type: .giftAccepted,
                    receiverId: "user123",
                    senderId: "user456",
                    senderNickname: "김서현",
                    keyringName: "귀여운 키링",
                    postOfficeId: "post123",
                    isRead: false,
                    createdAt: Date().addingTimeInterval(-30)
                ),
                onTap: {}
            )

            NotificationItemView(
                notification: KeychyNotification(
                    type: .giftAccepted,
                    receiverId: "user123",
                    senderId: "user789",
                    senderNickname: "박철수",
                    keyringName: "멋진 키링",
                    postOfficeId: "post456",
                    isRead: true,
                    createdAt: Date().addingTimeInterval(-3600)
                ),
                onTap: {}
            )

            NotificationItemView(
                notification: KeychyNotification(
                    type: .giftAccepted,
                    receiverId: "user123",
                    senderId: "user999",
                    senderNickname: "이영희",
                    keyringName: "특별한 키링",
                    postOfficeId: "post789",
                    isRead: true,
                    createdAt: Date().addingTimeInterval(-86400)
                ),
                onTap: {}
            )
        }
        .padding()
    }
}
