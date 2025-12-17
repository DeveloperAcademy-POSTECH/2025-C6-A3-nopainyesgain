//
//  MyPageView.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

struct MyPageView: View {
    @Environment(UserManager.self) private var userManager
    @Environment(IntroViewModel.self) private var introViewModel
    @Bindable var router: NavigationRouter<HomeRoute>
    
    @State private var viewModel = MyPageViewModel()
    
    // 타이틀 표시 여부
    @State private var showTitle = true
    
    var body: some View {
        ZStack {
            mainContent
            alerts
            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGesture(enabled: true)
    }
}

// MARK: - UI Components
extension MyPageView {
    /// 메인 컨텐츠
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 30) {
                userInfo
                itemAndCharge
                VStack(spacing: 20) {
                    manageAccount
                    manageNotification
                    usingGuide
                    termsOfService
                    miscellaneous
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 25)
            .padding(.bottom, 30)
            .adaptiveTopPaddingAlt()
            .overlay(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("scroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .scrollIndicators(.never)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            withAnimation(.easeOut(duration: 0.2)) {
                showTitle = offset >= -10
            }
        }
        .onAppear {
            viewModel.checkNotificationPermission()
            viewModel.isMarketingNotificationEnabled = userManager.currentUser?.marketingAgreed ?? false

            if let uid = Auth.auth().currentUser?.uid {
                userManager.loadUserInfo(uid: uid) { _ in }
            }
        }
        .onChange(of: userManager.currentUser?.marketingAgreed) { oldValue, newValue in
            viewModel.isMarketingNotificationEnabled = newValue ?? false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.checkNotificationPermission()
        }
        .alert(viewModel.alertType.title, isPresented: $viewModel.showSettingsAlert) {
            Button("취소", role: .cancel) {
                viewModel.checkNotificationPermission()
            }
            Button("설정으로 이동") {
                NotificationManager.shared.openSettings()
            }
        } message: {
            Text(viewModel.alertType.message)
        }
        .alert("재인증 필요", isPresented: $viewModel.showReauthAlert) {
            Button("재인증하기") {
                viewModel.startReauthentication(userManager: userManager, introViewModel: introViewModel)
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("보안을 위해 재인증이 필요합니다")
        }
        .allowsHitTesting(!viewModel.showLogoutAlert && !viewModel.showDeleteAccountAlert && !viewModel.showLoadingAlert)
    }
    /// 내 정보 섹션
    private var userInfo: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(userManager.currentUser?.nickname ?? "알 수 없음")
                .typography(.notosans20M)
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
            Image(.myCoin)
                .padding(.vertical, 8)
                .padding(.horizontal, 35)
            
            Text("코인")
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
            Image(.myKeyringCount)
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
            Image(.myCopyPass)
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

// MARK: - 알림 설정
extension MyPageView {
    private var managaNotificaiton: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("알림 설정")

            // 전체 알림
            HStack {
                menuItemText("알림 설정")
                Spacer()
                Toggle("", isOn: $viewModel.isPushNotificationEnabled)
                    .labelsHidden()
                    .tint(.gray700)
                    .onChange(of: viewModel.isPushNotificationEnabled) { oldValue, newValue in
                        viewModel.handlePushNotificationToggle(newValue: newValue)
                    }
            }
            .padding(.bottom, 15)

            // 마케팅 정보 알림
            HStack {
                menuItemText("마케팅 정보 알림")
                    .opacity(viewModel.isPushNotificationEnabled ? 1.0 : 0.3)
                Spacer()
                Toggle("", isOn: $viewModel.isMarketingNotificationEnabled)
                    .labelsHidden()
                    .tint(.gray700)
                    .disabled(!viewModel.isPushNotificationEnabled)
                    .opacity(viewModel.isPushNotificationEnabled ? 1.0 : 0.3)
                    .onChange(of: viewModel.isMarketingNotificationEnabled) { oldValue, newValue in
                        viewModel.handleMarketingToggle(newValue: newValue, userManager: userManager)
                    }
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
                    
                    // 앱 버전 정보 가져오기!
                    subText("ver \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
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

// MARK: - 약관 및 정책
extension MyPageView {
    private var termsOfService: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("약관 및 정책")
            
            /// 개인정보 처리 방침 및 이용약관
            myPageBtn(type: .termsAndPolicy)
            
            Divider()
                .padding(.top, 20)
        }
    }
}

// MARK: - 로그아웃, 회원탈퇴
extension MyPageView {
    private var guitar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("기타")
            VStack(alignment: .leading, spacing: 15) {

                /// 로그아웃
                Button {
                    viewModel.showLogoutAlert = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        viewModel.logoutAlertScale = 1.0
                    }
                } label: {
                    Text("로그아웃")
                        .typography(.suit17M)
                        .foregroundStyle(.black100)
                }
                .buttonStyle(.plain)

                /// 회원탈퇴
                Button {
                    viewModel.showDeleteAccountAlert = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        viewModel.deleteAccountAlertScale = 1.0
                    }
                } label: {
                    Text("회원 탈퇴")
                        .typography(.suit17M)
                        .foregroundStyle(.black100)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            .typography(.suit16M)
            .foregroundStyle(.black100)
    }
    
    /// 서브 텍스트 (회색, suit12M25)
    private func subText(_ text: String) -> some View {
        Text(text)
            .typography(.suit12M25)
            .foregroundStyle(.gray600)
    }
    
    /// 뒤로가기
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
            }
        }
    }
}

// MARK: - 커스텀 네비게이션 바
extension MyPageView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽)
            BackToolbarButton {
                router.pop()
            }
        } center: {
            // Center (중앙)
            Text("마이페이지")
                .opacity(showTitle ? 1 : 0)
        } trailing: {
            // Trailing (오른쪽) - 빈 공간
            Spacer()
                .frame(width: 44, height: 44)
        }
    }
}
