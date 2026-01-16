//
//  CollectionKeyringDetailView+Alerts.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - 알럿/팝업 관련
extension CollectionKeyringDetailView {
    @ViewBuilder
    var alertOverlays: some View {
        if showDeleteAlert || showDeleteCompleteAlert {
            deleteAlertOverlay
        }

        if showCopyAlert || showCopyingAlert || showCopyCompleteAlert || showCopyLackAlert || showInvenFullAlert {
            copyAlertOverlay
        }

        if showPackageAlert || showPackingAlert {
            packageAlertOverlay
        }

        if showImageSaved {
            imageSaveAlert
        }

        if showVideoSaved {
            videoSaveAlert
        }

        if isGeneratingVideo {
            videoGeneratingAlert
        }
    }
    
    // MARK: - Delete Alerts
    private var deleteAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)
            
            if showDeleteAlert {
                DeletePopup(
                    title: "[\(keyring.name)]\n삭제할까요?",
                    message: "삭제한 키링은 뭉치에서도 사라져요.",
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = false
                        }
                    },
                    onConfirm: {
                        handleDeleteConfirm()
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
    }
    
    func handleDeleteConfirm() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            showDeleteAlert = false
            ToastManager.shared.show()
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDeleteAlert = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
    
    // MARK: - Copy Alerts
    private var copyAlertOverlay: some View {
        
        ZStack {
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
            
            if showCopyingAlert {
                LoadingAlert(type: .short, message: nil)
                    .zIndex(101)
            }
            
            if showCopyCompleteAlert {
                KeychyAlert(
                    type: .copy,
                    message: "키링이 복사되었어요!",
                    isPresented: $showCopyCompleteAlert
                )
                .zIndex(101)
            }
            
            if showCopyLackAlert {
                LackPopup(
                    title: "복사권이 부족해요",
                    message: "충전하러 갈까요?",
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
        }
    }
    
    func handleCopyConfirm() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            showCopyAlert = false
            ToastManager.shared.show()
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showCopyAlert = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                print("UID를 찾을 수 없습니다")
                return
            }
            
            // 1. 복사권 개수 확인
            if self.viewModel.copyVoucher <= 0 {
                print("복사권 부족")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showCopyLackAlert = true
                }
                return
            }
            
            // 2. 인벤토리 용량 확인
            self.viewModel.checkInventoryCapacity(userId: uid) { hasSpace in
                DispatchQueue.main.async {
                    if !hasSpace {
                        // 보관함 가득 찬 경우
                        print("보관함 가득 찬")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.showInvenFullAlert = true
                        }
                        return
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showCopyingAlert = true
                    }
                    
                    // 3. 복사권 있고, 인벤토리 여유 있음 -> 복사 진행
                    self.viewModel.copyKeyring(uid: uid, keyring: self.keyring) { success, newKeyringId in
                        DispatchQueue.main.async {
                            self.showCopyingAlert = false
                            
                            if success {
                                print("키링 복사 성공")
                                
                                // 복사권 개수 새로고침
                                self.refreshCopyVoucher()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        self.showCopyCompleteAlert = true
                                    }
                                }
                            } else {
                                print("키링 복사 실패")
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    self.showCopyLackAlert = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Package Alerts
    private var packageAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)
            
            if showPackageAlert {
                PackagePopup(
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showPackageAlert = false
                        }
                    },
                    onConfirm: {
                        handlePackageConfirm()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
            
            if showPackingAlert {
                LoadingAlert(
                    type: .longWithPresent,
                    message: "선물 포장 중.."
                )
                .zIndex(101)
            }
        }
    }
    
    func handlePackageConfirm() {
        // 네트워크 체크
        guard NetworkManager.shared.isConnected else {
            showPackageAlert = false
            ToastManager.shared.show()
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showPackageAlert = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                print("UID를 찾을 수 없습니다")
                return
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self.showPackingAlert = true
            }
            
            print("포장하기 시작")
            
            self.viewModel.packageKeyring(uid: uid, keyring: keyring) { success, postOfficeId in
                DispatchQueue.main.async {
                    if success {
                        print("포장 완료 - PostOffice ID: \(postOfficeId ?? "nil")")
                        self.postOfficeId = postOfficeId ?? ""
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.handlePackingComplete()
                        }
                    } else {
                        print("포장 실패")
                        
                        self.showPackingAlert = false
                    }
                }
            }
        }
    }
    
    func handlePackingComplete() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSheetPresented = false
            isNavigatingDeeper = true
            
            router.push(.packageCompleteView(keyring: keyring, postOffice: postOfficeId))
        }
    }
    
    // MARK: - Image Save Alert
    private var imageSaveAlert: some View {
        KeychyAlert(
            type: .imageSave,
            message: "이미지가 저장되었어요!",
            isPresented: $showImageSaved
        )
            .zIndex(101)
    }

    // MARK: - Video Save Alert
    private var videoSaveAlert: some View {
        KeychyAlert(
            type: .imageSave,
            message: "영상이 저장되었어요!",
            isPresented: $showVideoSaved
        )
            .zIndex(101)
    }

    // MARK: - Video Generating Alert
    private var videoGeneratingAlert: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("영상 생성 중...")
                    .typography(.suit17SB)
                    .foregroundColor(.white)

                Text("5~10초 소요")
                    .typography(.suit14M)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .zIndex(100)
        }
    }
}
