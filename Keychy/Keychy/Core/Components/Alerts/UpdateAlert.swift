//
//  UpdateAlert.swift
//  Keychy
//
//  Created by 길지훈 on 1/8/26.
//

import SwiftUI

/// 앱 업데이트 안내 Alert
/// 새로운 버전이 출시되었을 때 사용자에게 업데이트를 유도
struct UpdateAlert: View {
    let appStoreURL: String

    var body: some View {
        VStack {
            VStack(spacing: 10) {
                Image(.updateAlert)
                    .padding(.top, 8)

                Text("KEYCHY 업데이트 안내")
                    .typography(.suit20B)

                Text("새로운 업데이트가 있어요.\n지금 최신 버전으로 만나보세요.")
                    .typography(.suit17SB)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 8)

                Button {
                    openAppStore()
                } label: {
                    Text("지금 업데이트 하기")
                        .typography(.suit17SB)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
            }
            .padding(14)
        }
        .glassEffect(in: .rect(cornerRadius: 40))
        .padding(.horizontal, 51)
    }

    /// App Store 앱 페이지 열기
    private func openAppStore() {
        guard let url = URL(string: appStoreURL) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    UpdateAlert(appStoreURL: "https://apps.apple.com/app/id123456789")
}
