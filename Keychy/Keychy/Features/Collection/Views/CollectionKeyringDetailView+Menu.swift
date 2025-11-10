//
//  CollectionKeyringDetailView+Menu.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - 메뉴 (편집/복사/삭제)
extension CollectionKeyringDetailView {
    // 본인 것인지 확인
    var isMyKeyring: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userUID") else {
            return false
        }
        return keyring.authorId == currentUserId
    }
    
    var menuOverlay: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMenu = false
                    }
                }
            
            KeyringMenu(
                position: menuPosition,
                isMyKeyring: isMyKeyring,
                onEdit: {
                    handleMenuEdit()
                },
                onCopy: {
                    handleMenuCopy()
                },
                onDelete: {
                    handleMenuDelete()
                }
            )
            .zIndex(50)
        }
    }
    
// MARK: - 메뉴 액션들
    // MARK: - 편집
    private func handleMenuEdit() {
        isSheetPresented = false
        isNavigatingDeeper = true
        showMenu = false
        
        router.push(.keyringEditView(keyring))
    }
    
    // MARK: - 복사
    private func handleMenuCopy() {
        showMenu = false
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            
            showCopyAlert = true
        }
    }
    
    // MARK: - 삭제
    private func handleMenuDelete() {
        showMenu = false
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDeleteAlert = true
        }
    }
    
    // MARK: - 포장
    func handlePackageConfirm() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showPackageAlert = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
                print("UID를 찾을 수 없습니다")
                return
            }
            
            print("포장하기 시작")
            
            viewModel.packageKeyring(uid: uid, keyring: keyring) { success, postOfficeId in
                if success {
                    print("포장 완료 - PostOffice ID: \(postOfficeId ?? "nil")")
                    self.postOfficeId = postOfficeId ?? ""
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPackingAlert = true
                    }
                } else {
                    print("포장 실패")
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

}
