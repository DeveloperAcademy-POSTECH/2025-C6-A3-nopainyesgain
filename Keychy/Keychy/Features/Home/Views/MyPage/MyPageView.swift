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

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

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
    /// 내 아이템 - 충전하기
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
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
            .padding(.bottom, 15)
            .background(.gray50)
            .cornerRadius(15)
        }
    }

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

    /// 계정 관리
    private var manageAccount: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("계정 관리")

            Button {
                router.push(.changeName)
            } label: {
                Text("닉네임 변경")
                    .typography(.suit17M)
                    .foregroundStyle(.black100)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.top, 20)
        }
    }

    /// 알림 설정
    private var manageNotification: some View {
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

    /// 이용 안내
    private var usingGuide: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("이용 안내")

            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 0) {
                    menuItemText("앱 버전")
                        .padding(.trailing, 12)

                    subText("ver \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                }

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

    /// 약관 및 정책
    private var termsOfService: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("약관 및 정책")

            Button {
                router.push(.termsAndPolicy)
            } label: {
                Text("개인정보 처리 방침 및 이용약관")
                    .typography(.suit17M)
                    .foregroundStyle(.black100)
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.top, 20)
        }
    }

    /// 기타 (로그아웃, 회원탈퇴)
    private var miscellaneous: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("기타")
            VStack(alignment: .leading, spacing: 15) {

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

// MARK: - Alerts
extension MyPageView {
    /// 모든 Alert
    private var alerts: some View {
        Group {
            if viewModel.showLogoutAlert { logoutAlert }
            if viewModel.showDeleteAccountAlert { deleteAccountAlert }
            if viewModel.showLoadingAlert { loadingAlert }
        }
    }

    private var logoutAlert: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {}

            AccountAlert(
                checkmarkScale: viewModel.logoutAlertScale,
                title: "로그아웃",
                text: "로그아웃 하시겠습니까?",
                cancelText: "취소",
                confirmText: "로그아웃",
                confirmBtnColor: .main500,
                onCancel: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        viewModel.logoutAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.showLogoutAlert = false
                    }
                },
                onConfirm: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        viewModel.logoutAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.showLogoutAlert = false
                        viewModel.logout(userManager: userManager, introViewModel: introViewModel)
                    }
                }
            )
            .padding(.horizontal, 51)
            .padding(.bottom, 30)
        }
    }

    private var deleteAccountAlert: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {}

            AccountAlert(
                checkmarkScale: viewModel.deleteAccountAlertScale,
                title: "회원 탈퇴",
                text: """
                    탈퇴 시 보유중인 아이템과
                    키링 및 계정 정보는 즉시 삭제되어
                    복구가 불가해요.

                    정말 탈퇴하시겠어요?
                    """,
                cancelText: "취소",
                confirmText: "탈퇴하기",
                confirmBtnColor: .pink100,
                onCancel: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        viewModel.deleteAccountAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.showDeleteAccountAlert = false
                    }
                },
                onConfirm: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        viewModel.deleteAccountAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.showDeleteAccountAlert = false
                        viewModel.deleteAccount(userManager: userManager, introViewModel: introViewModel)
                    }
                }
            )
            .padding(.horizontal, 51)
            .padding(.bottom, 30)
        }
    }

    private var loadingAlert: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {}
            LoadingAlert(type: .short, message: nil)
        }
    }
}

// MARK: - Reusable Components
extension MyPageView {
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .typography(.suit15M25)
            .foregroundStyle(.gray500)
            .padding(.bottom, 12)
    }

    private func menuItemText(_ text: String) -> some View {
        Text(text)
            .typography(.suit16M)
            .foregroundStyle(.black100)
    }

    private func subText(_ text: String) -> some View {
        Text(text)
            .typography(.suit12M25)
            .foregroundStyle(.gray600)
    }

    private func openInstagram(username: String) {
        let instagramURL = URL(string: "instagram://user?username=\(username)")!
        let webURL = URL(string: "https://www.instagram.com/\(username)")!

        if UIApplication.shared.canOpenURL(instagramURL) {
            UIApplication.shared.open(instagramURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - Navigation
extension MyPageView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("마이페이지")
                .opacity(showTitle ? 1 : 0)
        } trailing: {
            Spacer()
                .frame(width: 44, height: 44)
        }
        .opacity(viewModel.showSettingsAlert || viewModel.showDeleteAccountAlert || viewModel.showLogoutAlert || viewModel.showReauthAlert || viewModel.showLoadingAlert || viewModel.isShowingAppleSignIn ? 0 : 1)
    }
}
