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
        isSheetPresented = false
        showMenu = false
        
        refreshCopyVoucher()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCopyAlert = true
        }
    }
    
    // MARK: - 삭제
    private func handleMenuDelete() {
        isSheetPresented = false
        showMenu = false
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDeleteAlert = true
        }
    }

}
