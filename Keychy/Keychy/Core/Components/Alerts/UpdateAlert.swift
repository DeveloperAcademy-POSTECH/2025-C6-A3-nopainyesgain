//
//  UpdateAlert.swift
//  Keychy
//
//  Created by 길지훈 on 1/8/26.
//

import SwiftUI

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

    private func openAppStore() {
        guard let url = URL(string: appStoreURL) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    UpdateAlert()
}
