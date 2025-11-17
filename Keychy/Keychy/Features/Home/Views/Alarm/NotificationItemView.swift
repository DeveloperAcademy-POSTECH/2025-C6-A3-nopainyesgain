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
    let notification: Notification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 선물 아이콘
                Image("AlarmIconFill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(.mainOpacity10)
                    )

                // 알림 내용
                VStack(alignment: .leading, spacing: 4) {
                    // 메시지
                    Text(notification.message)
                        .typography(.suit15B)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 시간
                    Text(notification.relativeTimeString)
                        .typography(.suit13M)
                        .foregroundStyle(.gray400)
                }

                Spacer()

                // 미확인 표시 점
                if !notification.isRead {
                    Circle()
                        .fill(.main)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? .white100 : .mainOpacity15)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview("미확인 알림") {
    NotificationItemView(
        notification: Notification(
            type: .giftAccepted,
            receiverId: "user123",
            senderId: "user456",
            senderNickname: "김서현",
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
        notification: Notification(
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
                notification: Notification(
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
                notification: Notification(
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
                notification: Notification(
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
