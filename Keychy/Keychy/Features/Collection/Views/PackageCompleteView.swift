//
//  PackageCompleteView.swift
//  Keychy
//
//  Created by Jini on 11/7/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore

struct PackageCompleteView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    @State private var currentPage: Int = 0
    @State private var authorName: String = ""
    @State private var scene: KeyringCellScene?
    @State private var isLoading: Bool = true
    
    private let totalPages = 2
    
    let keyring: Keyring
    
    var body: some View {
        VStack(spacing: 0) {
            Text("키링 포장이 완료되었어요!")
                .typography(.suit20B)
                .foregroundColor(.black100)
                .padding(.bottom, 9)
            
            Text("친구에게 공유하세요")
                .typography(.suit16M)
                .foregroundColor(.black100)
                .padding(.bottom, 42)
            
            
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 38) {
                        // 첫 번째 페이지
                        packagePreviewPage
                            .frame(width: 240)
                            .offset(x: -10)
                        
                        // 두 번째 페이지
                        keyringOnlyPage
                            .frame(width: 240)
                            .offset(x: -10)
                    }
                    .padding(.horizontal, (geometry.size.width - 240) / 2)
                }
                .content.offset(x: -CGFloat(currentPage) * (240 + 38))
                .padding(.leading, 10)
                .frame(width: geometry.size.width, alignment: .leading)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 38
                            if value.translation.width < -threshold && currentPage < totalPages - 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            } else if value.translation.width > threshold && currentPage > 0 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            }
                        }
                )
            }
            .frame(height: 460)
            
            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.black100 : Color.gray200)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 8)
            
            Spacer()
                .frame(height: 24)
            
            // 버튼들
            HStack(spacing: 16) {
                VStack(spacing: 9) {
                    LinkSaveButton
                    
                    Text("링크 복사")
                        .typography(.suit13SB)
                        .foregroundColor(.black100)

                }
                
                VStack(spacing: 9) {
                    ImageSaveButton
                    
                    Text("이미지 저장")
                        .typography(.suit13SB)
                        .foregroundColor(.black100)
                }
            }
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            backToolbarItem
        }
        .onAppear {
            hideTabBar()
            //fetchAuthorName()
        }
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
    
    // MARK: - 첫 번째 페이지 (포장 전체 뷰)
    private var packagePreviewPage: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .bottom) {
                ZStack {
                    Image("PackageBG")
                        .resizable()
                        .frame(width: 220, height: 270)
                        
                        .offset(y: -15)
                    
                    SpriteView(
                        scene: createMiniScene(keyring: keyring),
                        options: [.allowsTransparency]
                    )
                    .frame(width: 195, height: 300)
                    .rotationEffect(.degrees(10))
                    .offset(y: -7)
                }
                
                ZStack(alignment: .top) {
                    Image("PackageFG")
                        .resizable()
                        .frame(width: 240, height: 390)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("의자자") //keyring.name
                                .typography(.nanum15EB25)
                                .foregroundColor(.white100)
                            
                            Text("@리에르") //authorName
                                .typography(.suit10SB)
                                .foregroundColor(.white100)
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, 18)
                    .offset(y: 46)

                }

            }
            .padding(.bottom, 30)
            
            // 하단 버튼
            HStack {
                Image("LinkSimple")
                    .resizable()
                    .frame(width: 18, height: 18)
                
                Text("탭하여 복사")
                    .typography(.suit15M25)
                    .foregroundColor(.black100)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 두 번째 페이지 (키링만 있는 뷰)
    private var keyringOnlyPage: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .bottom) {
                Image("QRKeyring")
                    .resizable()
                    .frame(width: 240, height: 390)
                
                ZStack {
                    Rectangle()
                        .fill(.white100)
                        .frame(width: 215, height: 215)
                    
                    Image("tempQR") // 실제 QR 이미지
                        .resizable()
                        .frame(width: 210, height: 210)
                }
                .offset(y: -8)

            }
            .padding(.bottom, 30)
            
            // 하단 버튼
            Text("QR 코드로 전달하기")
                .typography(.suit15M25)
                .foregroundColor(.black100)
            
        }
        .frame(width: 240, height: 390)
        .padding(.horizontal, 20)
    }
    
    private var firestoreDocumentId: String? {
        viewModel.keyringDocumentIdByLocalId[keyring.id]
    }
    
    private func createMiniScene(keyring: Keyring) -> KeyringCellScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 195, height: 300),
            customBackgroundColor: .clear,
            zoomScale: 1.8,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        )
        scene.scaleMode = .aspectFill
        return scene
    }
    
    // MARK: - 하단 버튼
    private var LinkSaveButton: some View {
        Button(action: {
            copyLink()
        }) {
            Image("Link")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .frame(width: 65, height: 65)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    
    private var ImageSaveButton: some View {
        Button(action: {
            //action()
        }) {
            Image("Save")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .frame(width: 65, height: 65)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    
    // MARK: - 액션
    private func copyLink() {
        guard let url = DeepLinkManager.createShareLink(keyringId: firestoreDocumentId!) else {
            print("링크 생성 실패")
            return
        }
        
        UIPasteboard.general.string = url.absoluteString
        print("링크 복사 완료: \(url.absoluteString)")
    }

    private func shareLink() {
        guard let url = DeepLinkManager.createShareLink(keyringId: firestoreDocumentId!) else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func saveImage() {
        // TODO: 이미지 저장 로직
        print("이미지 저장 - 현재 페이지: \(currentPage)")
    }
}

// MARK: - 툴바
extension PackageCompleteView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image("dismiss")
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    PackageCompleteView(router: NavigationRouter<CollectionRoute>(), viewModel: CollectionViewModel(), keyring: Keyring(name: "", bodyImage: "", soundId: "", particleId: "", memo: "", tags: [""], createdAt: Date(), authorId: "", selectedTemplate: "", selectedRing: "", selectedChain: "", originalId: "", chainLength: 6))
}
