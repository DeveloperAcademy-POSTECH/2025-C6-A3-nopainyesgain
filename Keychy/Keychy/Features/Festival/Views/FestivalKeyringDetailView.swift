//
//  FestivalKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 11/24/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore
import Photos

struct FestivalKeyringDetailView: View {
    @Bindable var festivalRouter: NavigationRouter<FestivalRoute>
    @Bindable var workshopRouter: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: Showcase25BoardViewModel
    
    @State var sheetDetent: PresentationDetent = .fraction(0.48)
    @State private var scene: KeyringDetailScene?
    @State private var isLoading: Bool = true
    @State var isSheetPresented: Bool = false
    @State var authorName: String = ""
    @State var copyVoucher: Int = 0
    @State var showCopyAlert: Bool = false
    @State var showCopyCompleteAlert: Bool = false
    @State var showCopyLackAlert: Bool = false
    @State var showCopyingAlert: Bool = false
    @State var showInvenFullAlert: Bool = false
    @State var showPackageAlert: Bool = false
    @State var showPackingAlert: Bool = false
    @State var menuPosition: CGRect = .zero

    let keyring: Keyring
    
    var body: some View {
        GeometryReader { geometry in
            let heightRatio = screenHeight / 852
            
            ZStack(alignment: .top) {
                Image("WhiteBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: shouldApplyBlur ? 10 : 0)
                    .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack(alignment: .center) {
                        keyringScene
                            .frame(height: geometry.size.height * 0.8)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
                            .blur(radius: shouldApplyBlur ? 10 : 0)
                            .animation(.easeInOut(duration: 0.3), value: shouldApplyBlur)
                        
                        bottomSection
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.942)
                            .blur(radius: shouldApplyBlur ? 15 : 0)
                    }
                }
                
//                if showMenu {
//                    menuOverlay
//                }
                
                if isLoading {
                    Color.black20
                        .ignoresSafeArea()
                        
                    LoadingAlert(type: .short, message: nil)
                        .zIndex(200)
                }
                
//                alertOverlays
//                    .position(
//                        x: geometry.size.width / 2,
//                        y: geometry.size.height / 2
//                    )
                
                customNavigationBar
                    .blur(radius: shouldApplyBlur ? 15 : 0)
                    .adaptiveTopPadding()
                    .zIndex(0)
            }
            
        }
        .ignoresSafeArea()
        //.adaptiveBottomPadding()
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(false)
        .sheet(isPresented: $isSheetPresented) {
            infoSheet
                .presentationDetents([.fraction(0.48), .fraction(0.93)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.48)))
                .interactiveDismissDisabled(false)
        }
        .onAppear {
            viewModel.fetchUserName(userId: keyring.authorId) { name in
                self.authorName = name
            }
        }
        .onDisappear {
            //handleViewDisappear()
        }
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            menuPosition = frame
        }
    }
    
    private var shouldApplyBlur: Bool {
        isLoading ||
        showCopyCompleteAlert ||
        showCopyingAlert ||
        showPackingAlert ||
        false
    }
    
//    // 복사권 개수 리프레쉬
//    func refreshCopyVoucher() {
//        guard let uid = UserDefaults.standard.string(forKey: "userUID") else { return }
//        
//        viewModel.fetchUserCollectionData(uid: uid) { success in
//            if success {
//                print("복사권 새로고침: \(viewModel.copyVoucher)개")
//            }
//        }
//    }
    
    /// 씬 스케일 (시트 최대화 시 작게, 최소화 시 크게)
    private var sceneScale: CGFloat {
        isSheetPresented == false ? 1.1 : 0.8
    }
    
    /// 씬 Y 오프셋 (시트 최대화 시 위로 이동)
    private var sceneYOffset: CGFloat {
        isSheetPresented == false ? 30 : -50
    }
}

// MARK: - 키링 씬
extension FestivalKeyringDetailView {
    var keyringScene: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 30)
                
                KeyringDetailSceneView(
                    keyring: keyring,
                    isLoading: $isLoading
                )
                
                Spacer()
            }
            .scaleEffect(sceneScale)
            .offset(y: sceneYOffset)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isSheetPresented)
            .allowsHitTesting(isSheetPresented == false)
        }
    }

}

// MARK: - 하단 영역
extension FestivalKeyringDetailView {
    // 하단 버튼 섹션 - 이미지 저장, 포장
    private var bottomSection: some View {
        HStack {
            voteButton
            
            Spacer()
            
            Button {
                // 정보 시트 열기
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    isSheetPresented = true
                    sheetDetent = .fraction(0.48)
                }
            } label: {
                Text("정보 보기")
                    .typography(.suit16M)
                    .foregroundStyle(.white100)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.main500)
            )
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            
            Spacer()
            
            copyButton
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 36, trailing: 16))
        .adaptiveBottomPadding()
        .opacity(isSheetPresented ? 0 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSheetPresented)
    }
    
    private var voteButton: some View {
        Button(action: {
            //captureAndSaveImage()
        }) {
            Image("imageDownload")
        }
        .frame(width: 48, height: 48)
        .glassEffect(.regular.interactive(), in: .circle)
    }
    
    private var copyButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPackageAlert = true
            }
        }) {
            Image("Copy")
        }
        .frame(width: 48, height: 48)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}

extension FestivalKeyringDetailView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            BackToolbarButton {
                isSheetPresented = false
                router.pop()
            }
        } center: {
            // Center (중앙) - 빈 공간
            Spacer()
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Spacer()
        }
    }
}

