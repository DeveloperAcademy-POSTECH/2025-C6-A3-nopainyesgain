//
//  PackageCompleteView.swift
//  Keychy
//
//  Created by Jini on 11/7/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore
import CoreImage

struct PackageCompleteView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    @State var currentPage: Int = 0
    @State var authorName: String = ""
    @State private var scene: KeyringCellScene?
    @State private var isLoading: Bool = false
    @State private var qrCodeImage: UIImage?
    @State private var shareLink: String = ""
    @State private var showLinkCopied: Bool = false
    @State var showImageSaved: Bool = false
    
    // 캡처용 씬 PNG 이미지
    @State var capturedSceneImage: UIImage?
    @State var isCapturingScene: Bool = false
    
    private let totalPages = 2
    
    // 씬의 RingType과 ChainType
    var ringType: RingType {
        RingType.fromID(keyring.selectedRing)
    }
    
    var chainType: ChainType {
        ChainType.fromID(keyring.selectedChain)
    }
    
    let keyring: Keyring
    let postOfficeId: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                packagedView
                    .blur(radius: shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            hideTabBar()
            fetchAuthorName()
            loadShareLink()
            captureSceneOnAppear()
        }
        .onDisappear() {
            showTabBar()
        }
    }
    
    // MARK: - 탭바 제어
    private func hideTabBar() {
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
    
    // 블러 처리
    private var shouldApplyBlur: Bool {
        isLoading ||
        showLinkCopied ||
        showImageSaved ||
        false
    }
    
    // MARK: - 씬을 PNG로 미리 캡처
    private func captureSceneOnAppear() {
        Task { @MainActor in
            // 씬 생성 및 PNG 캡처
            let captureScene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                targetSize: CGSize(width: 195, height: 300),
                customBackgroundColor: .clear,
                zoomScale: 1.8
            )
            
            guard let pngData = await captureScene.captureToPNG(),
                  let image = UIImage(data: pngData) else {
                return
            }

            self.capturedSceneImage = image
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
    
    // sharelink 로드
    private func loadShareLink() {
        let db = Firestore.firestore()
        
        db.collection("PostOffice")
            .document(postOfficeId)
            .getDocument { snapshot, error in
                if let error = error {
                    return
                }
                
                guard let data = snapshot?.data(),
                      let link = data["shareLink"] as? String else {
                    return
                }
                
                self.shareLink = link
                
                // QR 코드 생성
                self.generateQRCodeImage()
            }
    }
    
    // MARK: - 페이지 가로 스크롤
    private var pageScrollView: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 38) {
                    packagePreviewPage
                        .frame(width: 240)
                        .offset(x: -10)
                    
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
                        handleSwipe(value: value)
                    }
            )
        }
        .frame(height: 460)
    }
    
    // MARK: - 스와이프
    private func handleSwipe(value: DragGesture.Value) {
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
    
    // MARK: - 페이지 인디케이터
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.black100 : Color.gray200)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - 하단 이미지 저장 섹션
    private var imageSaveSection: some View {
        VStack(spacing: 9) {
            ImageSaveButton
            
            Text("이미지 저장")
                .typography(.suit13SB)
                .foregroundColor(.black100)
        }
    }
    
    // MARK: - 팝업
    private var linkCopiedAlert: some View {
        LinkCopiedPopup(isPresented: $showLinkCopied)
            .zIndex(101)
    }
    
    private var imageSaveAlert: some View {
        SavedPopup(isPresented: $showImageSaved, message: "이미지가 저장되었습니다.")
            .zIndex(101)
    }
    
    
    private var packagedView: some View {
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700
            
            ZStack {
                Image("GreenBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    Spacer()
                        .adaptiveTopPadding()
                    
                    VStack(spacing: 0) {
                        Text("키링 포장이 완료되었어요!")
                            .typography(.suit20B)
                            .foregroundColor(.black100)
                            
                            .padding(.bottom, 9)
                        
                        Text("링크나 QR로 바로 공유할 수 있어요.")
                            .typography(.suit16M)
                            .foregroundColor(.black100)
                    }
                    .padding(.top, isSmallScreen ? -70 : 78)
                    
                    Spacer()
                        .frame(height: isSmallScreen ? 24 : 48)
                    
                    PackagedKeyringView(
                        keyring: keyring,
                        postOfficeId: postOfficeId,
                        shareLink: shareLink,
                        authorName: authorName,
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
    
    // MARK: - 첫 번째 페이지 (포장 전체 뷰)
    private var packagePreviewPage: some View {
        VStack(spacing: 0) {
            packageImageStack
                .padding(.bottom, 30)
            
            copyLinkButton
        }
        .padding(.horizontal, 20)
    }
    
    var packageImageStack: some View {
        ZStack(alignment: .bottom) {
            packageBackground
            packageForeground
        }
    }
    
    private var packageBackground: some View {
        ZStack {
            Image("PackageBG")
                .resizable()
                .frame(width: 220, height: 270)
            
            // 항상 PNG 이미지 사용
            if let sceneImage = capturedSceneImage {
                Image(uiImage: sceneImage)
                    .resizable()
                    .frame(width: 195, height: 300)
                    .rotationEffect(.degrees(10))
                    .offset(y: -2)
            } else {
                // PNG 로딩 중
                LoadingAlert(type: .short, message: nil)
                    .frame(width: 195, height: 300)
                    .scaleEffect(0.6)
            }
        }
    }
    
    var packageForeground: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Image("PackageFG_T")
                    .resizable()
                    .frame(width: 240, height: 91)
                
                Image("PackageFG_B")
                    .resizable()
                    .frame(width: 240, height: 301)
                    .blendMode(.darken)
                    .offset(y: -2)
            }
            .frame(width: 240, height: 390)
            
            keyringInfoLabel
        }
    }
    
    private var keyringInfoLabel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(keyring.name)
                    .typography(.notosans15B)
                    .foregroundColor(.white100)
                
                Text("@\(authorName)")
                    .typography(.notosans10M)
                    .foregroundColor(.white100)
            }
            
            Spacer()
        }
        .padding(.leading, 18)
        .offset(y: 40)
    }
    
    private var copyLinkButton: some View {
        Button(action: {
            copyLink()
        }) {
            HStack {
                Image("LinkSimple")
                    .resizable()
                    .frame(width: 18, height: 18)
                
                Text("탭하여 복사")
                    .typography(.suit15M25)
                    .foregroundColor(.black100)
            }
        }
    }
    
    
    // MARK: - 두 번째 페이지 (키링만 있는 뷰)
    private var keyringOnlyPage: some View {
        VStack(spacing: 0) {
            qrCodeImageStack
                .padding(.bottom, 30)
            
            Text("")
                .typography(.suit15M25)
                .foregroundColor(.black100)
        }
        .frame(width: 240, height: 390)
        .padding(.horizontal, 20)
    }
    
    var qrCodeImageStack: some View {
        ZStack(alignment: .bottom) {
            Image("QRKeyring")
                .resizable()
                .frame(width: 240, height: 390)
            
            qrCodeContainer
        }
    }
    
    private var qrCodeContainer: some View {
        ZStack {
            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 205, height: 205)
            } else {
                LoadingAlert(type: .short, message: nil)
                    .frame(width: 205, height: 205)
                    .scaleEffect(0.6)
            }
        }
        .offset(x: -3, y: -24)
    }
    
    // MARK: - 하단 버튼
    private var ImageSaveButton: some View {
        Button(action: {
            saveImage()
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
    
    
    // MARK: - 링크 복사
    private func copyLink() {
        if shareLink.isEmpty {
            return
        }
        
        UIPasteboard.general.string = shareLink
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showLinkCopied = true
        }
    }
    
    // MARK: - QR 코드 생성
    private func generateQRCodeImage() {
        if shareLink.isEmpty {
            return
        }
        
        qrCodeImage = generateQRCode(from: shareLink)
    }

    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return UIImage() }
        
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return UIImage() }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return UIImage()
    }
    
    private func saveImage() {
        captureAndSaveCurrentPage { success in
            if success {
                print("이미지 저장 완료")
            } else {
                print("이미지 저장 실패")
            }
        }
    }
}

// MARK: - 툴바
extension PackageCompleteView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.reset()
            } label: {
                Image("dismiss")
                    .foregroundColor(.primary)
            }
        }
    }
}

extension PackageCompleteView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            Button {
                router.reset()
            } label: {
                Image("dismiss")
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
        } center: {
            // Center (중앙) - 빈 공간
            Spacer()
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Spacer()
        }
    }
}
