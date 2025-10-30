//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import SpriteKit

struct CollectionKeyringDetailView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @State private var sheetDetent: PresentationDetent = .height(76)
    @State private var scene: KeyringDetailScene?
    @State private var isLoading: Bool = true
    
    let keyring: Keyring
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene = scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                        .allowsHitTesting(true) // ⭐️ 터치 허용
                } else {
                    Color.gray.opacity(0.1)
                }
//                // Scene 표시
//                //KeyringDetailSceneView(keyring: keyring)
//                SpriteView(scene: createDetailScene(size: size))
            }
            
            .onAppear {
                if scene == nil {
                    createDetailScene(size: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(keyring.name)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .sheet(isPresented: .constant(true)) {
            infoSheet
                .presentationDetents([.height(76), .height(395)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(395)))
                .interactiveDismissDisabled()
                
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // UITabBar 직접 제어
            // sheet를 계속 true로 띄워놓으니까 .toolbar(.hidden, for: .tabBar)가 안 먹혀서 강제로 제어하는 코드를 넣음
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController?.findTabBarController() {
                UIView.animate(withDuration: 0.3) {
                    tabBarController.tabBar.isHidden = true
                }
            }
        }
        .onDisappear { // 일단 여기서 더 딥하게 들어가지는 않으니까 이렇게 해두겠음
            // 화면 나갈 때 탭바 다시 보이기
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = window.rootViewController?.findTabBarController() {
                UIView.animate(withDuration: 0.3) {
                    tabBarController.tabBar.isHidden = false
                }
            }
        }
        .toolbar {
            backToolbarItem
            menuToolbarItem
        }
    }
    
    private func createDetailScene(size: CGSize) {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        print("🎬 Creating detail scene with ring: \(ringType), chain: \(chainType), size: \(size)")
        
        let newScene = KeyringDetailScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: size, // 전체 화면 크기 사용
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isLoading = false
                    }
                }
            }
        )
        newScene.size = size
        newScene.scaleMode = .aspectFill
        newScene.backgroundColor = .clear
        
        // 저장된 사운드/파티클 효과 적용
        if keyring.soundId != "none" {
            newScene.currentSoundId = keyring.soundId
        }
        if keyring.particleId != "none" {
            newScene.currentParticleId = keyring.particleId
        }
        
        scene = newScene
        print("✅ Detail scene created with size: \(size)")
    }
}

// MARK: - 툴바
extension CollectionKeyringDetailView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
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
                // 액션 추가
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
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
                        .padding(.top, sheetDetent == .height(395) ? 30 : 10)
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
            .scrollDisabled(sheetDetent == .height(76))
        }
        .toolbar(.hidden, for: .tabBar)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetDetent == .height(395) ? Color.white : Color.clear)
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
                // 이미지 다운로드 로직
            }) {
                Image("Download")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            Spacer()
            
            Text("정보")
                .typography(.suit15B25)
            
            Spacer()
            
            Button(action: {
                // 포장 로직
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
            
            Text("@\(keyring.authorId)") // 얘 닉네임으로 바꿔야함
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
        
        private var lineCount: Int {
            let lines = memo.components(separatedBy: .newlines)
            return max(1, lines.count)
        }
        
        // 줄 수에 따른 높이 계산
        private var memoHeight: CGFloat {
            switch lineCount {
            case 1:
                return 60
            case 2:
                return 80
            case 3:
                return 100
            default:
                // 4줄 이상일 경우
                return 100
            }
        }
        
        var body: some View {
            Group {
                if lineCount >= 4 {
                    // 4줄 이상일 때 스크롤 가능
                    ScrollView {
                        Text(memo)
                            .typography(.suit16M25)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: memoHeight)
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
                        .frame(maxWidth: .infinity, minHeight: memoHeight, alignment: .leading)
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
        /// 화면을 삐져나가면 스크롤 적용 후 왼쪽정렬, 아니면 스크롤 없이 가운데정렬
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

#Preview {
    CollectionKeyringDetailView(
        router: NavigationRouter<CollectionRoute>(), keyring: Keyring(name: "궁극의 또치 키링", bodyImage: "dsflksdkl", soundId: "sdfsdf", particleId: "dsfsdag", memo: "메모 테스트입니다", tags: ["태그 1", "태그 2"], createdAt: Date(), authorId: "dsfakldsk", selectedTemplate: "agdfsgd", selectedRing: "gafdgfd", selectedChain: "sgsafs", chainLength: 5)
    )
}
