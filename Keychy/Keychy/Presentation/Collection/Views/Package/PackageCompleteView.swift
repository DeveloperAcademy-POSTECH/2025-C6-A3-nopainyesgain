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
    @State var qrCodeImage: UIImage?
    @State private var shareLink: String = ""
    @State private var showLinkCopied: Bool = false
    @State var showImageSaved: Bool = false
    
    // 캐시된 키링 이미지
    @State var cachedKeyringImage: UIImage?
    
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
            TabBarManager.hide()
            fetchAuthorName()
            loadShareLink()
            loadCachedImage()
        }
        .onDisappear() {
            TabBarManager.show()
            cleanupImages()
        }
    }
    
    private func cleanupImages() {
        cachedKeyringImage = nil
        qrCodeImage = nil
    }
    
    // 블러 처리
    private var shouldApplyBlur: Bool {
        isLoading ||
        showLinkCopied ||
        showImageSaved ||
        false
    }
    
    // MARK: - 캐시된 이미지 로드
    private func loadCachedImage() {
        guard let keyringID = keyring.documentId else {
            print("키링 ID 없음")
            return
        }
        
        if let imageData = KeyringImageCache.shared.load(for: keyringID, type: .thumbnail),
           let image = UIImage(data: imageData) {
            self.cachedKeyringImage = image
        } else {
            print("캐시된 이미지 없음: \(keyringID)")
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
    
    private var packagedView: some View {
        GeometryReader { geometry in
            let heightRatio = geometry.size.height / 852
            let isSmallScreen = geometry.size.height < 700
            
            ZStack {
                Image(.greenBackground)
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
}

// MARK: - 툴바
extension PackageCompleteView {
    private var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            Button {
                router.reset()
            } label: {
                Image(.dismiss)
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
