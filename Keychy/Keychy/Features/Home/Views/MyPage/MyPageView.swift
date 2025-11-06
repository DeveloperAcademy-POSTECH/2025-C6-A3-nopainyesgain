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
    @State private var isPushNotificationEnabled = false

    // 앱 버전 정보 가져오기!
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                userInfo
                itemAndCharge
                VStack(spacing: 20) {
                    managaAccount
                    managaNotificaiton
                    usingGuide
                    termsOfService
                    guitar
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 25)
            .padding(.bottom, 30)
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
        }
        .scrollIndicators(.never)
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

// MARK: - 내 아이템, 충전하기 섹션 (아이템 정보 불러오기 필요)
extension MyPageView {
    /// 내아이템 - 충전하기 헤더
    private var itemAndCharge: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("내 아이템")
                    .typography(.suit16M25)
                    .foregroundStyle(.black)
                
                Spacer()
                
                myPageBtn(type: .charge)
            }
            
            HStack(spacing: 20) {
                myCoin
                myKeyringCount
                myCopyPass
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
            .padding(.bottom, 15)
            .background(.gray50)
            .cornerRadius(15)
        }
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

            Text("\(userManager.currentUser?.coin ?? 0)")
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

            Text("\(userManager.currentUser?.keyrings.count ?? 0)/\(userManager.currentUser?.maxKeyringCount ?? 100)")
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

            Text("\(userManager.currentUser?.copyVoucher ?? 0)")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
    }
}

// MARK: - 계정 관리
extension MyPageView {
    private var managaAccount: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("계정 관리")
            
            myPageBtn(type: .changeName)
            
            Divider()
                .padding(.top, 20)
        }
    }
}

// MARK: - 알림 설정 (알림 로직 추가 필요)
extension MyPageView {
    private var managaNotificaiton: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("알림 설정")
            
            HStack {
                menuItemText("푸시 알림")
                Spacer()
                Toggle("", isOn: $isPushNotificationEnabled)
                    .labelsHidden()
                    .tint(.gray700)
            }
            Divider()
                .padding(.top, 20)
        }
    }
}

// MARK: - 이용 안내
extension MyPageView {
    private var usingGuide: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("이용 안내")
            
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 0) {
                    menuItemText("앱 버전")
                        .padding(.trailing, 12)
                    subText("ver \(appVersion)")
                }
                
                /// Keychy 인스타 그램 연결
                Button {
                      openInstagram(username: "keychy.app")
                  } label: {
                      Text("Contact to 운영자")
                          .typography(.suit17M)
                          .foregroundStyle(.black100)
                  }
                  .buttonStyle(.plain)
            }
            Divider()
                .padding(.top, 20)
        }
    }
    
    private func openInstagram(username: String) {
          let instagramURL = URL(string: "instagram://user?username=\(username)")!
          let webURL = URL(string: "https://www.instagram.com/\(username)")!

          if UIApplication.shared.canOpenURL(instagramURL) {
              // 인스타그램 앱이 설치되어 있으면 앱으로 열기
              UIApplication.shared.open(instagramURL)
          } else {
              // 앱이 없으면 Safari로 웹 열기
              UIApplication.shared.open(webURL)
          }
      }
}

// MARK: - 약관 및 정책 (약관, 정책 파일 확인 후 작업 필요)
extension MyPageView {
    private var termsOfService: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("약관 및 정책")
            Divider()
                .padding(.top, 20)
        }
    }
}

// MARK: - 기타
extension MyPageView {
    private var guitar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("기타")
            VStack(alignment: .leading, spacing: 15) {
                myPageBtn(type: .deleteAccout)
                myPageBtn(type: .logout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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

// MARK: - 화면 이동
extension MyPageView {
    
    // 버튼 종류
    enum MyPageButtonType {
        case charge
        case changeName
        case helloMaster
        case deleteAccout
        case logout
        
        var text: String {
            switch self {
            case .charge:
                return "충전하기"
            case .changeName:
                return "닉네임 변경"
            case .helloMaster:
                return "Contact to 운영자"
            case .deleteAccout:
                return "회원 탈퇴"
            case .logout:
                return "로그아웃"
            }
        }
        
        // MARK: - 루트 수정 필요
        var route: HomeRoute? {
            switch self {
            case .charge:
                return .coinCharge
            case .changeName:
                return .changeName
            case .helloMaster:
                return .coinCharge
            case .deleteAccout:
                return .coinCharge
            case .logout:
                return .coinCharge
            }
        }
    }
    
    // 각 기능 버튼
    private func myPageBtn(type: MyPageButtonType) -> some View {
        Button {
            guard let route = type.route else { return }
            router.push(route)
        } label: {
            Text(type.text)
                .typography(.suit17M)
                .foregroundStyle(.black100)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 재사용 컴포넌트
extension MyPageView {
    /// 섹션 타이틀 텍스트 (회색, suit15M25, padding bottom 12)
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit15M25)
            .foregroundStyle(.gray500)
            .padding(.bottom, 12)
    }
    
    /// 메뉴 아이템 텍스트 (검은색, suit17M)
    private func menuItemText(_ text: String) -> some View {
        Text(text)
            .typography(.suit17M)
            .foregroundStyle(.black100)
    }
    
    /// 서브 텍스트 (회색, suit12M25)
    private func subText(_ text: String) -> some View {
        Text(text)
            .typography(.suit12M25)
            .foregroundStyle(.gray600)
    }
}
