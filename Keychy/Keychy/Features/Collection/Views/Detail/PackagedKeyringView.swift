//
//  PackagedKeyringView.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI
import SpriteKit
import CoreImage

struct PackagedKeyringView: View {
    let keyring: Keyring
    let postOfficeId: String
    let shareLink: String
    let authorName: String
    
    @Binding var isLoading: Bool
    @State var currentPage: Int = 0
    @State private var qrCodeImage: UIImage?
    @State var cachedKeyringImage: UIImage?
    
    var onImageSaved: (() -> Void)?
    var onLinkCopied: (() -> Void)?
    
    private let totalPages = 2
    
    private var ringType: RingType {
        RingType.fromID(keyring.selectedRing)
    }
    
    private var chainType: ChainType {
        ChainType.fromID(keyring.selectedChain)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            pageScrollView
            
            pageIndicator
            
            Spacer()
                .frame(height: 24)
            
            imageSaveSection
        }
        .padding(.horizontal, 20)
        .onAppear {
            loadCachedImage()
        }
        .onDisappear {
            cleanupImages()
        }
        .onChange(of: shareLink) { oldValue, newValue in
            // shareLink가 업데이트되면 QR 코드 생성
            if !newValue.isEmpty {
                generateQRCodeImage()
            }
        }
    }
    
    private func cleanupImages() {
        cachedKeyringImage = nil
        qrCodeImage = nil
    }
    
    // MARK: - 캐시된 이미지 로드
    private func loadCachedImage() {
        guard let keyringID = keyring.documentId else {
            print("키링 ID 없음")
            isLoading = false
            return
        }
        
        // 캐시에서 이미지 로드
        if let imageData = KeyringImageCache.shared.load(for: keyringID),
           let image = UIImage(data: imageData) {
            self.cachedKeyringImage = image
            checkLoadingComplete()
        } else {
            print("캐시된 이미지 없음: \(keyringID)")
            // 캐시가 없으면 임시로 빈 상태 표시하거나 다시 캡처
            isLoading = false
        }
    }
    
    // 로딩 완료 체크
    private func checkLoadingComplete() {
        if cachedKeyringImage != nil {
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
    
    // MARK: - Page Scroll View
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
    
    // MARK: - Page Indicator
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
    
    // MARK: - Image Save Section
    private var imageSaveSection: some View {
        VStack(spacing: 9) {
            ImageSaveButton
            
            Text("이미지 저장")
                .typography(.suit13SB)
                .foregroundColor(.black100)
        }
    }
    
    // MARK: - Swipe Handler
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
}

// MARK: - Pages
extension PackagedKeyringView {
    // 첫 번째 페이지
    var packagePreviewPage: some View {
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
            Image(.packageBG)
                .resizable()
                .frame(width: 220, height: 270)
            
            // 캐시된 이미지 사용
             if let cachedImage = cachedKeyringImage {
                 Image(uiImage: cachedImage)
                     .resizable()
                     .scaledToFit()
                     .frame(width: 195, height: 300)
                     .scaleEffect(0.92)
                     .rotationEffect(.degrees(10))
                     .offset(y: -5)
                     .shadow(
                         color: Color(hex: "#56522E").opacity(0.35),
                         radius: 5,
                         x: 4,
                         y: 14
                     )
             } else {
                 // 이미지 로딩 중
                 LoadingAlert(type: .short, message: nil)
                     .frame(width: 195, height: 300)
                     .scaleEffect(0.6)
             }
        }
    }
    
    private var packageForeground: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Image(.packageFGT)
                    .resizable()
                    .frame(width: 240, height: 91)
                
                Image(.packageFGB)
                    .resizable()
                    .frame(width: 240, height: 301)
                    .blendMode(.darken)
                    .opacity(0.55)
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
            onLinkCopied?()
        }) {
            HStack {
                Image(.linkSimple)
                    .resizable()
                    .frame(width: 18, height: 18)
                
                Text("탭하여 복사")
                    .typography(.suit15M25)
                    .foregroundColor(.black100)
            }
        }
    }
    
    // 두 번째 페이지
    var keyringOnlyPage: some View {
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
            Image(.qrKeyring)
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
}

// MARK: - Buttons
extension PackagedKeyringView {
    var ImageSaveButton: some View {
        Button(action: {
            saveImage()
        }) {
            Image(.save)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
        .frame(width: 65, height: 65)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}

// MARK: - Helper Functions
extension PackagedKeyringView {
    func copyLink() {
        if shareLink.isEmpty {
            return
        }
        
        UIPasteboard.general.string = shareLink
    }
    
    func generateQRCodeImage() {
        if shareLink.isEmpty {
            return
        }
        
        qrCodeImage = generateQRCode(from: shareLink)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return UIImage()
        }
        
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return UIImage()
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return UIImage()
    }
    
    func saveImage() {
        captureAndSaveCurrentPage { success in
            if success {
                print("저장 완료")
            }
        }
    }
}
