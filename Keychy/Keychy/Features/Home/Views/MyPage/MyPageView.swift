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
    @State private var notificationManager = NotificationManager.shared
    @State private var isPushNotificationEnabled = false
    @State private var isMarketingNotificationEnabled = false
    @State private var showSettingsAlert = false
    @State private var alertType: AlertType = .turnOn
    
    // 로그아웃/회원탈퇴 Alert
    @State private var showLogoutAlert = false
    @State private var logoutAlertScale: CGFloat = 0.3
    @State private var showDeleteAccountAlert = false
    @State private var deleteAccountAlertScale: CGFloat = 0.3
    
    // 재인증 필요 Alert
    @State private var showReauthAlert = false
    
    // 로딩 Alert
    @State private var showLoadingAlert = false
    @State private var loadingAlertScale: CGFloat = 0.3
    
    // Apple Sign In 재인증용
    @State private var currentNonce: String?
    @State private var authCoordinator: AppleAuthCoordinator?
    @State private var isShowingAppleSignIn = false

    // 타이틀 표시 여부
    @State private var showTitle = true

    var body: some View {
        ZStack {
            // 메인 컨텐츠
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
                .adaptiveTopPaddingAlt()
            }
            .scrollIndicators(.never)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // 아래로 드래그 (스크롤 위로)
                        if value.translation.height < -10 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showTitle = false
                            }
                        }
                        // 위로 드래그 (스크롤 아래로)
                        else if value.translation.height > 10 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showTitle = true
                            }
                        }
                    }
            )
            .onAppear {
                notificationManager.checkPermission { isAuthorized in
                    isPushNotificationEnabled = isAuthorized
                }
                isMarketingNotificationEnabled = userManager.currentUser?.marketingAgreed ?? false

                // Firestore에서 사용자 정보 새로 로드
                if let uid = Auth.auth().currentUser?.uid {
                    userManager.loadUserInfo(uid: uid) { _ in }
                }
            }
            .onChange(of: userManager.currentUser?.marketingAgreed) { oldValue, newValue in
                // UserManager의 marketingAgreed가 변경되면 토글 상태도 동기화
                isMarketingNotificationEnabled = newValue ?? false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                notificationManager.checkPermission { isAuthorized in
                    isPushNotificationEnabled = isAuthorized
                }
            }
            .alert(alertType.title, isPresented: $showSettingsAlert) {
                Button("취소", role: .cancel) {
                    // 토글 원위치
                    notificationManager.checkPermission { isAuthorized in
                        isPushNotificationEnabled = isAuthorized
                    }
                }
                Button("설정으로 이동") {
                    notificationManager.openSettings()
                }
            } message: {
                Text(alertType.message)
            }
            .alert("재인증 필요", isPresented: $showReauthAlert) {
                Button("재인증하기") {
                    // Apple Sign In으로 재인증
                    startReauthentication()
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("보안을 위해 재인증이 필요합니다")
            }
            .allowsHitTesting(!showLogoutAlert && !showDeleteAccountAlert && !showLoadingAlert)
            
            // 로그아웃 Alert
            if showLogoutAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // 배경 클릭 시 아무 동작 하지 않음 (상호작용 차단)
                        }
                    
                    AccountAlert(
                        checkmarkScale: logoutAlertScale,
                        title: "로그아웃",
                        text: "로그아웃 하시겠습니까?",
                        cancelText: "취소",
                        confirmText: "로그아웃",
                        confirmBtnColor: .main500,
                        onCancel: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                logoutAlertScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showLogoutAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                logoutAlertScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showLogoutAlert = false
                                logout()
                            }
                        }
                    )
                    .padding(.horizontal, 51)
                    .padding(.bottom, 30)
                }
            }
            
            // 회원탈퇴 Alert
            if showDeleteAccountAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // 배경 클릭 시 아무 동작 하지 않음 (상호작용 차단)
                        }
                    
                    AccountAlert( 
                        checkmarkScale: deleteAccountAlertScale,
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
                                deleteAccountAlertScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showDeleteAccountAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                deleteAccountAlertScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showDeleteAccountAlert = false
                                deleteAccount()
                            }
                        }
                    )
                    .padding(.horizontal, 51)
                    .padding(.bottom, 30)
                }
            }
            
            // 회원탈퇴 로딩 Alert
            if showLoadingAlert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}
                    LoadingAlert(type: .short, message: nil)
                }
            }

            // 커스텀 네비게이션 바
            customNavigationBar
                .opacity(showSettingsAlert || showDeleteAccountAlert || showLogoutAlert || showReauthAlert || showLoadingAlert || isShowingAppleSignIn ? 0 : 1)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - 내 정보 섹션
extension MyPageView {
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
            Image("myCoin")
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

// MARK: - 알림 설정
extension MyPageView {
    // Alert 타입
    enum AlertType {
        case turnOn
        case turnOff
        
        var title: String {
            switch self {
            case .turnOn:
                return "알림 권한이 필요해요"
            case .turnOff:
                return "알림을 끄시겠어요?"
            }
        }
        
        var message: String {
            switch self {
            case .turnOn:
                return "설정에서 알림을 켜주세요"
            case .turnOff:
                return "설정에서 알림을 끌 수 있어요"
            }
        }
    }
    
    private var managaNotificaiton: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("알림 설정")

            // 전체 알림
            HStack {
                menuItemText("알림 설정")
                Spacer()
                Toggle("", isOn: $isPushNotificationEnabled)
                    .labelsHidden()
                    .tint(.gray700)
                    .onChange(of: isPushNotificationEnabled) { oldValue, newValue in
                        handleToggleChange(newValue: newValue)
                    }
            }
            .padding(.bottom, 15)

            // 마케팅 정보 알림
            HStack {
                menuItemText("마케팅 정보 알림")
                    .opacity(isPushNotificationEnabled ? 1.0 : 0.3)
                Spacer()
                Toggle("", isOn: $isMarketingNotificationEnabled)
                    .labelsHidden()
                    .tint(.gray700)
                    .disabled(!isPushNotificationEnabled)
                    .opacity(isPushNotificationEnabled ? 1.0 : 0.3)
                    .onChange(of: isMarketingNotificationEnabled) { oldValue, newValue in
                        handleMarketingToggleChange(newValue: newValue)
                    }
            }

            Divider()
                .padding(.top, 20)
        }
    }
    
    /// 전체 알림 토글 변경 처리
    private func handleToggleChange(newValue: Bool) {
        notificationManager.checkPermission { isAuthorized in
            if newValue {
                // 토글 ON 시도
                if isAuthorized {
                    // 이미 허용됨
                    isPushNotificationEnabled = true
                } else {
                    // 권한 없음 -> 권한 요청
                    notificationManager.requestPermission { granted in
                        if granted {
                            isPushNotificationEnabled = true
                        } else {
                            // 권한 거부됨 -> 설정 이동 Alert
                            alertType = .turnOn
                            showSettingsAlert = true
                        }
                    }
                }
            } else {
                // 토글 OFF 시도
                if isAuthorized {
                    // 현재 권한이 있는 상태에서 끄려고 함 -> 설정으로 안내 (끄기)
                    alertType = .turnOff
                    showSettingsAlert = true
                } else {
                    // 이미 꺼진 상태 -> 그대로 유지
                    isPushNotificationEnabled = false
                }
            }
        }
    }

    /// 마케팅 정보 알림 토글 변경 처리
    private func handleMarketingToggleChange(newValue: Bool) {
        // 전체 알림이 꺼져있으면 아무것도 안함
        guard isPushNotificationEnabled else {
            return
        }

        // Firestore에 마케팅 동의 저장
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("User")
            .document(uid)
            .updateData(["marketingAgreed": newValue]) { [weak userManager] error in
                if let error = error {
                    print("마케팅 알림 설정 저장 실패: \(error.localizedDescription)")
                    // 실패 시 원래대로 되돌리기
                    DispatchQueue.main.async {
                        isMarketingNotificationEnabled = !newValue
                    }
                } else {
                    print("마케팅 알림 설정 저장 성공: \(newValue)")
                    // UserManager의 currentUser도 즉시 업데이트
                    DispatchQueue.main.async {
                        if var user = userManager?.currentUser {
                            user.marketingAgreed = newValue
                            userManager?.currentUser = user
                            userManager?.saveToCache()
                        }
                    }
                }
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
                    showLogoutAlert = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        logoutAlertScale = 1.0
                    }
                } label: {
                    Text("로그아웃")
                        .typography(.suit17M)
                        .foregroundStyle(.black100)
                }
                .buttonStyle(.plain)
                
                /// 회원탈퇴
                Button {
                    showDeleteAccountAlert = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        deleteAccountAlertScale = 1.0
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
    
    private func logout() {
        do {
            // 1. Firebase Auth 로그아웃
            try Auth.auth().signOut()

            // 2. UserManager 초기화
            userManager.clearUserInfo()

            // 3. 로그인 상태 변경 → RootView가 자동으로 IntroView로 전환
            introViewModel.isLoggedIn = false
            introViewModel.needsProfileSetup = false
        } catch {
            // 로그아웃 실패 처리
        }
    }
    
    // MARK: - Apple Sign In 재인증
    private func startReauthentication() {
        let nonce = randomNonceString()
        currentNonce = nonce

        // Apple Sign In 시트 표시 시작 → 네비게이션 바 숨김
        isShowingAppleSignIn = true

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        // Coordinator 생성 및 저장
        let coordinator = AppleAuthCoordinator(
            nonce: nonce,
            onSuccess: { [self] credential in
                self.isShowingAppleSignIn = false
                self.handleReauthSuccess(credential: credential)
            },
            onFailure: { [self] error in
                // Apple 재인증 취소 또는 실패 → 네비게이션 바 복원
                self.isShowingAppleSignIn = false
            }
        )
        authCoordinator = coordinator

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.performRequests()
    }
    
    private func handleReauthSuccess(credential: AuthCredential) {
        guard let user = Auth.auth().currentUser else {
            return
        }

        // LoadingAlert 표시
        showLoadingAlert = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            loadingAlertScale = 1.0
        }

        user.reauthenticate(with: credential) { _, error in
            if error != nil {
                // LoadingAlert 숨기기
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    loadingAlertScale = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showLoadingAlert = false
                }
            } else {
                deleteAccountAfterReauth(user: user)
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            return
        }

        let uid = user.uid

        // LoadingAlert 표시
        showLoadingAlert = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
            loadingAlertScale = 1.0
        }

        // 1. 먼저 Firebase Auth 계정 삭제 시도 (재인증 필요 여부 확인)
        user.delete { error in
            if let error = error {
                // LoadingAlert 숨기기
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    loadingAlertScale = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showLoadingAlert = false
                }

                // 재인증 필요 에러 처리
                let nsError = error as NSError
                if nsError.code == 17014 { // FIRAuthErrorCodeRequiresRecentLogin
                    showReauthAlert = true
                }
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                userManager.deleteUserData(uid: uid) { result in
                    // LoadingAlert 숨기기
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        loadingAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showLoadingAlert = false
                    }

                    // 3. UserManager 초기화 및 로그인 화면으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        userManager.clearUserInfo()  // 로컬 캐시 정리
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                    }
                }
            }
        }
    }

    // 재인증 후 회원탈퇴 진행
    private func deleteAccountAfterReauth(user: FirebaseAuth.User) {
        let uid = user.uid

        // 1. Firebase Auth 계정 삭제
        user.delete { error in
            if error != nil {
                // LoadingAlert 숨기기
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    loadingAlertScale = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showLoadingAlert = false
                }
            } else {
                // 2. Auth 삭제 성공 → Firestore 데이터 삭제
                userManager.deleteUserData(uid: uid) { result in
                    // LoadingAlert 숨기기
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        loadingAlertScale = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showLoadingAlert = false
                    }

                    // 3. UserManager 초기화 및 로그인 화면으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        userManager.clearUserInfo()  // 로컬 캐시 정리
                        introViewModel.isLoggedIn = false
                        introViewModel.needsProfileSetup = false
                    }
                }
            }
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
        case termsAndPolicy
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
            case .termsAndPolicy:
                return "개인정보 처리 방침 및 이용약관"
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
            case .termsAndPolicy:
                return .termsAndPolicy
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
                .typography(type == .charge ? .suit15M25 : .suit17M)
                .foregroundStyle(type == .charge ? .gray500 : .black100)
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
