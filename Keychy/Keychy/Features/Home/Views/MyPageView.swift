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
        VStack(alignment: .center, spacing: 30) {
            VStack(alignment: .center, spacing: 8) {
                Text(userManager.currentUser?.nickname ?? "알 수 없음")
                    .typography(.suit20B)
                Text(userManager.currentUser?.email ?? "알 수 없음")
                    .typography(.suit15R)
            }
            .frame(maxWidth: .infinity)

            HStack {
                HStack(spacing: 7) {
                    Text("현재 보유한 체리")
                        .typography(.suit16M25)
                        .foregroundStyle(.black)
                    
                    Text("\(userManager.currentUser?.coin ?? 0)")
                        .typography(.nanum16EB)
                        .foregroundStyle(.main500)
                }

                Spacer()

                Button {
                    router.push(.coinCharge)
                } label: {
                    Text("충전하기")
                        .typography(.suit15M25)
                        .foregroundStyle(.gray500)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 27)
            .frame(maxWidth: .infinity, minHeight: 55, maxHeight: 55, alignment: .center)
            .background(.gray50)
            .cornerRadius(15)

            Spacer()

            Button {
                logout()
                router.push(.introView) // TODO: 로그인 처리 더 해야됨.
            } label: {
                Text("로그아웃")
                    .typography(.suit17M)
                    .foregroundStyle(.black100)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 25)
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

#Preview {
    NavigationStack {
        MyPageView(router: NavigationRouter<HomeRoute>())
    }
}
