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
        
//        if showCopyAlert || showCopyCompleteAlert || showCopyLackAlert {
//            copyAlertOverlay
//        }
        
        if showPackageAlert || showPackingAlert {
            packageAlertOverlay
        }
        
        if showImageSaved {
            imageSaveAlert
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
                    title: "[\(keyring.name)]\n정말 삭제하시겠어요?",
                    message: "한 번 삭제하면 복구 할 수 없습니다.",
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
        }
    }
    
    func handleCopyConfirm() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showCopyAlert = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                print("UID를 찾을 수 없습니다")
                return
            }
            
            if viewModel.copyVoucher > 0 {
                viewModel.copyKeyring(uid: uid, keyring: keyring) { success, newKeyringId in
                    if success {
                        print("키링 복사 성공")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showCopyCompleteAlert = true
                        }
                    }
                }
            } else {
                print("복사권 부족")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showCopyLackAlert = true
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
                PackingPopup(isPresented: $showPackingAlert)
                    .zIndex(100)
                    .onDisappear {
                        handlePackingComplete()
                    }
            }
        }
    }
    
    // MARK: - Image Save Alert
    private var imageSaveAlert: some View {
        SavedPopup(isPresented: $showImageSaved, message: "이미지가 저장되었습니다.")
            .zIndex(101)
    }
}
