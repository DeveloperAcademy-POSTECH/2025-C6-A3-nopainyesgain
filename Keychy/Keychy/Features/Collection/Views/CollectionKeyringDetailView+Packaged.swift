//
//  CollectionKeyringDetailView+Packaged.swift
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
    @State private var currentPage: Int = 0
    @State private var qrCodeImage: UIImage?
    @State private var isLoading: Bool = true
    
    private let totalPages = 2
    
    var body: some View {
        VStack(spacing: 0) {
            
            pageScrollView
            
            pageIndicator
            
            Spacer()
                .frame(height: 24)
            
            imageSaveSection
        }
        .padding(.horizontal, 20)
        .onChange(of: shareLink) { oldValue, newValue in
            // shareLink가 업데이트되면 QR 코드 생성
            if !newValue.isEmpty {
                generateQRCodeImage()
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
    
    private var packageImageStack: some View {
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
                .offset(y: -15)
            
            SpriteView(
                scene: createMiniScene(keyring: keyring),
                options: [.allowsTransparency]
            )
            .frame(width: 195, height: 300)
            .rotationEffect(.degrees(10))
            .offset(y: -7)
        }
    }
    
    private var packageForeground: some View {
        ZStack(alignment: .top) {
            Image("PackageFG")
                .resizable()
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
        .offset(y: 46)
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
    
    private var qrCodeImageStack: some View {
        ZStack(alignment: .bottom) {
            Image("QRKeyring")
                .resizable()
                .frame(width: 240, height: 390)
            
            qrCodeContainer
        }
    }
    
    private var qrCodeContainer: some View {
        ZStack {
            Rectangle()
                .fill(.white100)
                .frame(width: 215, height: 215)
            
            if let qrCodeImage = qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 210, height: 210)
            } else {
                ProgressView()
                    .frame(width: 210, height: 210)
            }
        }
        .offset(y: -12)
    }
}

// MARK: - Buttons
extension PackagedKeyringView {
    var ImageSaveButton: some View {
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
}

// MARK: - Helper Functions
extension PackagedKeyringView {
    func createMiniScene(keyring: Keyring) -> KeyringCellScene {
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
    
    func copyLink() {
        if shareLink.isEmpty {
            print("ShareLink가 비어있습니다")
            return
        }
        
        UIPasteboard.general.string = shareLink
        print("링크 복사 완료: \(shareLink)")
    }
    
    func generateQRCodeImage() {
        if shareLink.isEmpty {
            print("ShareLink가 비어있습니다")
            return
        }
        
        qrCodeImage = generateQRCode(from: shareLink)
        print("QR 코드 생성 완료: \(shareLink)")
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
        print("이미지 저장 - 현재 페이지: \(currentPage)")
        // TODO: 이미지 저장 로직
    }
}
