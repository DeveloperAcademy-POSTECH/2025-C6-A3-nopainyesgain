//
//  CollectionKeyringPackageView.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI
import FirebaseFirestore

// 포장된 키링 보이는 뷰
struct CollectionKeyringPackageView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    
    @State var loadedPostOfficeId: String = ""
    @State var packageAuthorName: String = ""
    @State var packagedDate: Date?
    @State var shareLink: String = ""
    @State var isLoading: Bool = true
    @State var showUnpackAlert: Bool = false
    @State var showUnpackCompleteAlert: Bool = false
    @State var showLinkCopied: Bool = false
    
    // 이미지 저장 관련
    @State var showImageSaved: Bool = false
    @State var checkmarkScale: CGFloat = 0.0
    @State var checkmarkOpacity: Double = 0.0
    @State var showUIForCapture: Bool = true  // 캡처 시 UI 표시 여부
    
    let keyring: Keyring
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                packagedView
                    .blur(radius: shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
                if isLoading {
                    Color.black20
                        .ignoresSafeArea()
                    
                    LoadingAlert(type: .short, message: nil)
                        .zIndex(101)
                }
                
                // 포장 풀기 알럿
                if showUnpackAlert || showUnpackCompleteAlert {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    if showUnpackAlert {
                        UnpackPopup(
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showUnpackAlert = false
                                }
                            },
                            onConfirm: {
                                handleUnpackConfirm()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .zIndex(100)
                    }
                    
                    // 포장 풀기 완료 알럿
                    if showUnpackCompleteAlert {
                        KeychyAlert(
                            type: .unpack,
                            message: "선물 포장을 풀었어요",
                            isPresented: $showUnpackCompleteAlert
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .zIndex(101)
                    }
                }
                
                if showImageSaved {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    KeychyAlert(type: .imageSave, message: "이미지가 저장되었어요!", isPresented: $showImageSaved)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .zIndex(101)
                }
                
                if showLinkCopied {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    KeychyAlert(type: .linkCopy, message: "링크가 복사되었어요!", isPresented: $showLinkCopied)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .zIndex(101)
                }
                
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .zIndex(0)
            }
            .padding(.top, 1)
        }
        .ignoresSafeArea()
        //.navigationTitle(keyring.name)
        .navigationBarBackButtonHidden(true)
//        .toolbar(.hidden, for: .tabBar)
//        .toolbar {
//            backToolbarItem
//            unpackToolbarItem
//        }
        .onAppear {
            hideTabBar()
            loadPackagedKeyringInfo()
        }
        .onDisappear {
            showTabBar()
        }
    }
    
    // MARK: - 탭바 제어
    func hideTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = true
            }
        }
    }
    
    func showTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = false
            }
        }
    }
    
    private var shouldApplyBlur: Bool {
        isLoading ||
        showUnpackCompleteAlert ||
        showImageSaved ||
        showLinkCopied ||
        false
    }
    
    private var imageSaveAlert: some View {
        SavedPopup(isPresented: $showImageSaved, message: "이미지가 저장되었습니다.")
            .zIndex(101)
    }
    
    private var linkCopiedAlert: some View {
        LinkCopiedPopup(isPresented: $showLinkCopied)
            .zIndex(101)
    }
}

extension CollectionKeyringPackageView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            BackToolbarButton {
                router.pop()
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            // Center (중앙) - 빈 공간
            Text(keyring.name)
                .typography(.suit17M)
                .foregroundStyle(.gray600)
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showUnpackAlert = true
                }
            }) {
                Image("UnpackIcon")
                    .resizable()
                    .frame(width: 34, height: 34)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

extension CollectionKeyringPackageView {
    var packagedView: some View {
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700
            
            ZStack {
                // 배경 이미지 (초록 패턴)
                Image("GreenBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    Spacer()
                        .adaptiveTopPadding()
                        
                    // 상단 상태 바
                    packageStatusBar
                        .padding(.top, isSmallScreen ? -70 : 70) // -70 너무 아닌거 같은데 암튼 됨...
                    
                    Spacer()
                        .frame(height: isSmallScreen ? 24 : 48)
                    
                    // 포장된 키링 뷰
                    PackagedKeyringView(
                        keyring: keyring,
                        postOfficeId: loadedPostOfficeId,
                        shareLink: shareLink,
                        authorName: packageAuthorName,
                        isLoading: $isLoading,
                        onImageSaved: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showImageSaved = true
                            }
                        },
                        onLinkCopied: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showLinkCopied = true
                            }
                        }
                    )
                    .frame(height: isSmallScreen ? 500 : 600)
                    .scaleEffect(heightRatio)
                    
                    Spacer()
                        .adaptiveBottomPadding()
                }
            }
        }

    }
    
    var packageStatusBar: some View {
        HStack {
            Text("선물 수락 대기 중...")
                .typography(.suit15B25)
                .foregroundColor(.white100)
                .padding(.leading, 25)
            
            Spacer()
            
            if let date = packagedDate {
                Text("포장일 : \(formattedPackageDate(date))")
                    .typography(.suit14M)
                    .foregroundColor(.white100)
                    .padding(.trailing, 25)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(.black50)

    }
    
    func formattedPackageDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Toolbar
extension CollectionKeyringPackageView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image("backIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    var unpackToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showUnpackAlert = true
                }
            }) {
                Image("UnpackIcon")
                    .resizable()
                    .frame(width: 34, height: 34)
            }
        }
    }
}

// MARK: - Data Loading
extension CollectionKeyringPackageView {
    func loadPackagedKeyringInfo() {
        guard let keyringDocId = viewModel.keyringDocumentIdByLocalId[keyring.id] else {
            print("Keyring Document ID 없음")
            return
        }
        
        let db = Firestore.firestore()
        
        // PostOffice 정보 로드
        db.collection("PostOffice")
            .whereField("keyringId", isEqualTo: keyringDocId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("PostOffice 조회 실패: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("PostOffice 문서 없음")
                    return
                }
                
                self.loadedPostOfficeId = document.documentID
                
                let data = document.data()
                
                // 포장 날짜 로드
                if let timestamp = data["createdAt"] as? Timestamp {
                    self.packagedDate = timestamp.dateValue()
                }
                
                // shareLink 로드
                if let link = data["shareLink"] as? String {
                    self.shareLink = link
                    print("ShareLink 로드: \(link)")
                }
                
                // 발신자 정보 로드
                if let senderId = data["senderId"] as? String {
                    db.collection("User")
                        .document(senderId)
                        .getDocument { userSnapshot, userError in
                            if let userData = userSnapshot?.data(),
                               let name = userData["nickname"] as? String {
                                self.packageAuthorName = name
                            } else {
                                self.packageAuthorName = "알 수 없음"
                            }
                        }
                }
            }
    }
    
    func handleUnpackConfirm() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showUnpackAlert = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                print("UID를 찾을 수 없습니다")
                return
            }
            
            self.viewModel.unpackKeyring(
                uid: uid,
                keyring: self.keyring,
                postOfficeId: self.loadedPostOfficeId
            ) { success in
                if success {
                    print("포장 풀기 완료")
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showUnpackCompleteAlert = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        self.router.pop()
                    }
                } else {
                    print("포장 풀기 실패")
                }
            }
        }
    }
}
