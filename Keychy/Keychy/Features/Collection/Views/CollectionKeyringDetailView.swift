//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore

struct CollectionKeyringDetailView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    @State private var sheetDetent: PresentationDetent = .height(76)
    @State private var scene: KeyringDetailScene?
    @State private var isLoading: Bool = true
    @State private var isSheetPresented: Bool = true
    @State private var isNavigatingDeeper: Bool = false
    @State private var authorName: String = ""
    @State private var showMenu: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteCompleteAlert: Bool = false
    @State private var showCopyAlert: Bool = false
    @State private var showCopyCompleteAlert: Bool = false
    @State private var menuPosition: CGRect = .zero
    
    let keyring: Keyring
    
    private var isMyKeyring: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userUID") else {
            return false
        }
        return keyring.authorId == currentUserId
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray50
                    .ignoresSafeArea()
                
                KeyringDetailSceneView(
                    keyring: keyring
                )
                .frame(maxWidth: .infinity)
                .scaleEffect(sceneScale)
                .offset(y: sceneYOffset)
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: sheetDetent)
                .allowsHitTesting(sheetDetent != .height(395))
                
                if showMenu { // 위치 조정 필요
                    Color.clear
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showMenu = false // dismiss용
                            }
                        }
                    
                    KeyringMenu(
                        position: menuPosition,
                        isMyKeyring: isMyKeyring,
                        onEdit: {
                            isSheetPresented = false
                            isNavigatingDeeper = true
                            showMenu = false
                            
                            router.push(.keyringEditView(keyring))
                        },
                        onCopy: {
                            showMenu = false
                            if let docId = firestoreDocumentId {
                                print("복사할 키링 Firestore ID: \(docId)")
                            } else {
                                print("복사 실패: Firestore ID 없음")
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showCopyAlert = true
                            }
                        },
                        onDelete: {
                            showMenu = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteAlert = true
                            }
                        }
                    )
                    .zIndex(50)
                }
                
                if showDeleteAlert || showDeleteCompleteAlert {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    if showDeleteAlert {
                        DeletePopup(
                            title: "[\(keyring.name)]\n정말 삭제하시겠어요?",
                            message: "한 번 삭제하면 복구 할 수 없습니다.",
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteAlert = false
                                }
                            },
                            onConfirm: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDeleteAlert = false
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                                        print("UID를 찾을 수 없습니다")
                                        return
                                    }
                                    
                                    viewModel.deleteKeyring(uid: uid, keyring: keyring) { success in
                                        if success {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                showDeleteCompleteAlert = true
                                            }
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                                router.pop()
                                            }
                                        } else {
                                            print("키링 삭제 실패")
                                        }
                                    }
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                    }
                    
                    if showDeleteCompleteAlert {
                        DeleteCompletePopup(isPresented: $showDeleteCompleteAlert)
                            .zIndex(100)
                    }
                }
                
                if showCopyAlert || showCopyCompleteAlert {
                    Color.black20
                        .ignoresSafeArea()
                        .zIndex(99)
                    
                    if showCopyAlert {
                        CopyPopup(
                            myCopyPass: viewModel.copyVoucher,
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCopyAlert = false
                                }
                            },
                            onConfirm: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCopyAlert = false
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                                        print("UID를 찾을 수 없습니다")
                                        return
                                    }
                                    
                                    viewModel.copyKeyring(uid: uid, keyring: keyring) { success, newKeyringId in
                                        if success {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                showCopyCompleteAlert = true
                                            }
                                        } else {
                                            print("키링 복사 실패")
                                        }
                                    }
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                    }
                    
                    if showCopyCompleteAlert {
                        CopyCompletePopup(isPresented: $showCopyCompleteAlert)
                            .zIndex(100)
                    }
                }
                    
            }
        }
        .ignoresSafeArea()
        .navigationTitle(keyring.name)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $isSheetPresented) {
            infoSheet
                .presentationDetents([.height(76), .height(395)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(395)))
                .interactiveDismissDisabled()
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            isSheetPresented = true
            isNavigatingDeeper = false
            hideTabBar()
            fetchAuthorName()
        }
        .onDisappear { // 일단 여기서 더 딥하게 들어가지는 않으니까 이렇게 해두겠음
            isSheetPresented = false
            // 화면 나갈 때 탭바 다시 보이기
            if !isNavigatingDeeper {
                showTabBar()
            }
        }
        .toolbar {
            backToolbarItem
            menuToolbarItem
        }
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            menuPosition = frame
        }
    }
    
    private var firestoreDocumentId: String? {
        viewModel.keyringDocumentIdByLocalId[keyring.id]
    }
    
    // MARK: - 탭바 제어
    // sheet를 계속 true로 띄워놓으니까 .toolbar(.hidden, for: .tabBar)가 안 먹혀서 강제로 제어하는 코드를 넣음
    private func hideTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = true
            }
        }
    }
    
    private func showTabBar() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBarController = window.rootViewController?.findTabBarController() {
            UIView.animate(withDuration: 0.3) {
                tabBarController.tabBar.isHidden = false
            }
        }
    }
    
    // Firebase에서 작성자 이름 가져오기 (나중에 viewModel로 이동 예정)
    private func fetchAuthorName() {
        let db = Firestore.firestore()
        
        db.collection("User")
            .document(keyring.authorId)
            .getDocument { snapshot, error in
                if let error = error {
                    self.authorName = "알 수 없음"
                    return
                }
                
                guard let data = snapshot?.data(),
                      let name = data["nickname"] as? String else {
                    self.authorName = "알 수 없음"
                    return
                }
                
                self.authorName = name
            }
    }
    /// 씬 스케일 (시트 최대화 시 작게, 최소화 시 크게)
    private var sceneScale: CGFloat {
        sheetDetent == .height(395) ? 0.8 : 1.3
    }
    
    /// 씬 Y 오프셋 (시트 최대화 시 위로 이동)
    private var sceneYOffset: CGFloat {
        sheetDetent == .height(395) ? -80 : 70
    }

}

// MARK: - PreferenceKey
struct MenuButtonPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - 툴바
extension CollectionKeyringDetailView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isSheetPresented = false
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var menuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
                    .contentShape(Rectangle())
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: MenuButtonPreferenceKey.self,
                                value: geometry.frame(in: .global)
                            )
                        }
                    )
            }
        }
    }
}

// MARK: - 키링 씬
extension CollectionKeyringDetailView {
    
}

// MARK: - 하단 바텀시트
extension CollectionKeyringDetailView {
    private var infoSheet: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    topSection
                        .padding(.top, sheetDetent == .height(395) ? 10 : 10)
                        .padding(.bottom, sheetDetent == .height(76) ? 14 : 0)
                        .animation(.easeInOut(duration: 0.35), value: sheetDetent)
                    
                    basicInfo
                    
                    // 메모 있으면
                    if let memo = keyring.memo, !memo.isEmpty {
                        memoSection
                    }
                    
                    // 태그 있으면
                    if !keyring.tags.isEmpty {
                        tagSection
                    }
                    
                    Spacer(minLength: 0)
                    
                }
                .padding(.horizontal, 16)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true)
        }
        .toolbar(.hidden, for: .tabBar)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetDetent == .height(395) ? .white100 : Color.clear)
        .shadow(
            color: Color.black.opacity(0.18),
            radius: 37.5,
            x: 0,
            y: -15
        )
        .animation(.easeInOut(duration: 0.3), value: sheetDetent)

    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }
    
    private var topSection: some View {
        HStack {
            Button(action: {
                // TODO: 이미지 다운로드 로직
            }) {
                Image("Save")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            Spacer()
            
            Text("정보")
                .typography(.suit15B25)
            
            Spacer()
            
            Button(action: {
                // TODO: 포장 로직 추가
                isSheetPresented = false
                isNavigatingDeeper = true
                router.push(.packageCompleteView)
            }) {
                Image("Present")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.top, 14)
    }
    
    private var basicInfo: some View {
        VStack {
            Text(keyring.name)
                .typography(.suit24B)
                .padding(.top, 30)
            
            Text(formattedDate(date: keyring.createdAt))
                .typography(.suit14M)
            
            Text("@\(authorName)")
                .typography(.suit15M25)
                .foregroundColor(.gray300)
                .padding(.top, 15)
        }
    }
    
    private var memoSection: some View {
        ZStack {
            MemoView(memo: keyring.memo ?? "")
        }
        .padding(.top, 15)
        
    }
    
    private struct MemoView: View {
        let memo: String
        @State private var textHeight: CGFloat = 0
        
        private var needsScroll: Bool {
            textHeight > 76 // 3줄 정도의 높이
        }
        
        private var displayHeight: CGFloat {
            if textHeight <= 36 { // 1줄
                return 60
            } else if textHeight <= 60 { // 2줄
                return 80
            } else if textHeight <= 76 { // 3줄
                return 100
            } else { // 4줄 이상
                return 100
            }
        }
        
        var body: some View {
            Group {
                if needsScroll {
                    // 4줄 이상일 때 스크롤 가능
                    ScrollView {
                        Text(memo)
                            .typography(.suit16M25)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        textHeight = geometry.size.height
                                    }
                                }
                            )
                    }
                    .scrollIndicators(.hidden)
                    .frame(height: displayHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray100, lineWidth: 1)
                    )
                } else {
                    // 3줄 이하일 때 스크롤 없음
                    Text(memo)
                        .typography(.suit16M25)
                        .foregroundColor(.black100)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true) // 수직으로 확장
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: TextHeightPreferenceKey.self,
                                    value: geometry.size.height
                                )
                            }
                        )
                        .onPreferenceChange(TextHeightPreferenceKey.self) { height in
                            textHeight = height
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray100, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var tagSection: some View {
        TagScrollView(tags: keyring.tags)
            .padding(.top, 15)
    }
    
    private struct TagScrollView: View {
        let tags: [String]
        @State private var contentWidth: CGFloat = 0
        @State private var containerWidth: CGFloat = 0
        
        // 가로 스크롤 여부 검사
        // 화면을 삐져나가면 스크롤 적용 후 왼쪽정렬, 아니면 스크롤 없이 가운데정렬
        private var needsScroll: Bool {
            contentWidth > containerWidth
        }
        
        var body: some View {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tagName: tag)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.onAppear {
                                contentWidth = contentGeometry.size.width
                            }
                        }
                    )
                    .frame(minWidth: needsScroll ? nil : geometry.size.width)
                }
                .frame(width: geometry.size.width, alignment: needsScroll ? .leading : .center)
                .disabled(!needsScroll)
                .onAppear {
                    containerWidth = geometry.size.width
                }
            }
            .frame(height: 36)
        }
    }
    
    private struct TagChip: View {
        let tagName: String
        
        var body: some View {
            ZStack {
                Text(tagName)
                    .typography(.nanum14EB18)
                    .foregroundColor(.main700)
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.mainOpacity15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.mainOpacity50, lineWidth: 1.5)
                    )
            }
        }

    }
}

// UITabBarController 찾기 헬퍼 익스텐션
extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        
        for child in children {
            if let tabBarController = child.findTabBarController() {
                return tabBarController
            }
        }
        
        return parent?.findTabBarController()
    }
}

struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
