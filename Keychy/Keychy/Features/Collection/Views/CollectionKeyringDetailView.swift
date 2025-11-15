//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import SpriteKit
import FirebaseFirestore
import Photos

struct CollectionKeyringDetailView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    @State var sheetDetent: PresentationDetent = .height(76)
    @State private var scene: KeyringDetailScene?
    @State private var isLoading: Bool = true
    @State var isSheetPresented: Bool = true
    @State var isNavigatingDeeper: Bool = false
    @State var authorName: String = ""
    @State var senderName: String = ""
    @State var copyVoucher: Int = 0
    @State var showMenu: Bool = false
    @State var showDeleteAlert: Bool = false
    @State var showDeleteCompleteAlert: Bool = false
    @State var showCopyAlert: Bool = false
    @State var showCopyCompleteAlert: Bool = false
    @State var showCopyLackAlert: Bool = false
    @State var showInvenFullAlert: Bool = false
    @State var showPackageAlert: Bool = false
    @State var showPackingAlert: Bool = false
    @State var menuPosition: CGRect = .zero

    // 이미지 저장 관련
    @State var showImageSaved: Bool = false
    @State var checkmarkScale: CGFloat = 0.0
    @State var checkmarkOpacity: Double = 0.0
    @State var showUIForCapture: Bool = true  // 캡처 시 UI 표시 여부
    
    // 포장 관련
    @State var postOfficeId: String = ""

    let keyring: Keyring
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("CollectionBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                keyringScene
                
                if showMenu {
                    menuOverlay
                }
                
                alertOverlays
                
                // 얘는 따로 빼니까 팝업 사이에 딜레이가 있어서 겹치는 문제가 있어서 일단 빼놨음
                if showCopyAlert || showCopyCompleteAlert || showCopyLackAlert || showInvenFullAlert {
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
                                handleCopyConfirm()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(100)
                    }
                    
                    if showCopyCompleteAlert {
                        CopyCompletePopup(isPresented: $showCopyCompleteAlert)
                            .zIndex(100)
                    }
                    
                    if showCopyLackAlert {
                        LackPopup(
                            title: "복사권이 부족합니다!",
                            onCancel: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCopyLackAlert = false
                                }
                            },
                            onConfirm: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showCopyLackAlert = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isSheetPresented = false
                                    isNavigatingDeeper = true
                                    
                                    router.push(.coinCharge)
                                }
                            }
                        )
                        .zIndex(100)
                    }
                    
                    if showInvenFullAlert {
                        InvenLackPopup(isPresented: $showInvenFullAlert)
                            .zIndex(100)
                    }
//                    if showInvenFullAlert {
//                        InvenLackPopup(
//                            onCancel: {
//                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                                    showInvenFullAlert = false
//                                }
//                            },
//                            onConfirm: {
//                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                                    showInvenFullAlert = false
//                                }
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                    isSheetPresented = false
//                                    isNavigatingDeeper = true
//                                    
//                                    router.push(.coinCharge)
//                                }
//                            }
//                        )
//                        .zIndex(100)
//                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(showUIForCapture ? keyring.name : "")
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $isSheetPresented) {
            infoSheet
                .presentationDetents([.height(76), .height(395)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(395)))
                .interactiveDismissDisabled()
        }
        
        .onAppear {
            handleViewAppear()
            refreshCopyVoucher()
        }
        .onDisappear {
            handleViewDisappear()
        }
        .toolbar {
            backToolbarItem
            menuToolbarItem
        }
        .toolbar(showUIForCapture ? .visible : .hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onPreferenceChange(MenuButtonPreferenceKey.self) { frame in
            menuPosition = frame
        }

    }
    
    // 복사권 개수 리프레쉬
    func refreshCopyVoucher() {
        guard let uid = UserDefaults.standard.string(forKey: "userUID") else { return }
        
        viewModel.fetchUserCollectionData(uid: uid) { success in
            if success {
                print("복사권 새로고침: \(viewModel.copyVoucher)개")
            }
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

// MARK: - 키링 씬
extension CollectionKeyringDetailView {
    var keyringScene: some View {
        KeyringDetailSceneView(
            keyring: keyring
        )
        .frame(maxWidth: .infinity)
        .scaleEffect(sceneScale)
        .offset(y: sceneYOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: sheetDetent)
        .allowsHitTesting(sheetDetent != .height(395))
    }
}
