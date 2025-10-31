//
//  MyPageView.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI
import FirebaseAuth

struct MyPageView: View {
    @Environment(UserManager.self) private var userManager
    @Bindable var router: NavigationRouter<HomeRoute>

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("이름")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(userManager.currentUser?.nickname ?? "알 수 없음")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("이메일")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(userManager.currentUser?.email ?? "알 수 없음")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("현재 보유한 체리")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(userManager.currentUser?.coin ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Button("충전하기") {
                    router.push(.coinCharge)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button("로그아웃") {
                logout()
                router.push(.introView)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .navigationTitle("마이페이지")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            userManager.clearUserInfo()
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
