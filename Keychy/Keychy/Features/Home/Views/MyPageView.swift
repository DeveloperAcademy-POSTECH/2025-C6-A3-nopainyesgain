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
            userInfo
            itemAndCharge
            
            Spacer()
        }
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

// MARK: - 내 정보 섹션
extension MyPageView {
    private var userInfo: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(userManager.currentUser?.nickname ?? "알 수 없음")
                .typography(.suit20B)
            Text(userManager.currentUser?.email ?? "알 수 없음")
                .typography(.suit15R)
        }
    }
}

// MARK: - 내 아이템, 충전하기 섹션
extension MyPageView {
    /// 내아이템 - 충전하기 헤더
    private var itemAndCharge: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("내 아이템")
                    .typography(.suit16M25)
                    .foregroundStyle(.black)
                
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
            
            HStack(spacing: 20) {
                myCoin
                myKeyringCount
                myCopyPass
            }
            .padding(.top, 5)
            .padding(.bottom, 15)
            .background(.gray50)
            .cornerRadius(15)
            
        }
        .padding(.horizontal, 11)
    }
    
    /// 내 코인
    private var myCoin: some View {
        VStack(spacing: 5) {
            Image("myCoin")
                .padding(.vertical, 8)
                .padding(.horizontal, 35)
            
            Text("열쇠")
                .typography(.suit12M)
                .foregroundStyle(.black100)
            
            Text("3,000")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
                
        }
    }
    
    /// 내 보유 키링
    private var myKeyringCount: some View {
        VStack(spacing: 5) {
            Image("myKeyringCount")
                .padding(.vertical, 8)
                .padding(.horizontal, 35)
            
            Text("보유 키링")
                .typography(.suit12M)
                .foregroundStyle(.black100)
            
            Text("30/100")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
    }
    
    /// 내 보유 복사권
    private var myCopyPass: some View {
        VStack(spacing: 5) {
            Image("myCopyPass")
                .padding(.vertical, 6)
                .padding(.horizontal, 33)
            
            Text("복사권")
                .typography(.suit12M)
                .foregroundStyle(.black100)
            
            Text("3/10")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
    }
}

// MARK: - 계정 관리

// MARK: - 알림 설정

// MARK: - 이용 안내

// MARK: - 약관 및 정책

// MARK: - 기타

