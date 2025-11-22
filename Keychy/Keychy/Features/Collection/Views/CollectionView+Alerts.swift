//
//  CollectionView+Alerts.swift
//  Keychy
//
//  Created by Jini on 11/12/25.
//

import SwiftUI

// MARK: - Alert & Popup 관련
extension CollectionView {
    @ViewBuilder
    var alertOverlays: some View {
        if let menuCategory = showingMenuFor {
            categoryMenuView(menuCategory: menuCategory)
        }
        
        if showRenameAlert {
            renameAlertOverlay
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        
        if showDeleteAlert || showDeleteCompleteAlert {
            deleteAlertOverlay
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        
        if showInvenExpandAlert || showPurchaseSuccessAlert || showPurchaseFailAlert {
            invenAlertOverlay
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
    
    private func categoryMenuView(menuCategory: String) -> some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    showingMenuFor = nil // dismiss용
                }
                .zIndex(49)
            
            CategoryContextMenu(
                categoryName: menuCategory,
                position: menuPosition,
                onRename: {
                    showingMenuFor = nil
                    renamingCategory = menuCategory
                    newCategoryName = menuCategory
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRenameAlert = true
                    }
                },
                onDelete: {
                    showingMenuFor = nil
                    deletingCategory = menuCategory
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDeleteAlert = true
                    }
                },
                onDismiss: {
                    showingMenuFor = nil
                }
            )
            .zIndex(50)
        }
    }
    
    // MARK: - 태그 이름 수정
    private var renameAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)
            
            TagInputPopup(
                type: .edit,
                tagName: $newCategoryName,
                availableTags: categories,
                onCancel: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRenameAlert = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        newCategoryName = ""
                    }
                },
                onConfirm: {_ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showRenameAlert = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        renameCategory()
                        newCategoryName = ""
                    }
                }
            )
            .transition(.scale.combined(with: .opacity))
            .zIndex(100)
        }
    }
    
    // MARK: - 태그 삭제
    private var deleteAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)
            
            if showDeleteAlert {
                DeletePopup(
                    title: "[\(deletingCategory)]\n삭제할까요?",
                    message: "태그를 삭제해도\n키링은 삭제되지 않아요.",
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            deletingCategory = ""
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
            confirmDeleteCategory()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDeleteCompleteAlert = true
            }
        }
    }
    
    // MARK: - 인벤토리 확장
    private var invenAlertOverlay: some View {
        ZStack {
            Color.black20
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showInvenExpandAlert = false
                    }
                }
                .zIndex(99)

            
            if showInvenExpandAlert {
                InvenExpandPopup(
                    myCoin: collectionViewModel.coin,
                    price: 20,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInvenExpandAlert = false
                        }
                    },
                    onConfirm: {
                        handleInvenExpandConfirm()
                    }
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }
//            if showInvenExpandAlert {
//                PurchasePopup(
//                    title: "보관함 확장",
//                    myCoin: collectionViewModel.coin,
//                    price: 20,
//                    scale: invenExpandAlertScale,
//                    onConfirm: {
//                        handleInvenExpandConfirm()
//                    }
//                )
//                .padding(.horizontal, 40)
//                .padding(.bottom, 30)
//                .transition(.scale.combined(with: .opacity))
//                .zIndex(100)
//            }
            
            if showPurchaseSuccessAlert {
                KeychyAlert(
                    type: .checkmark,
                    message: "구매가 완료되었어요!",
                    isPresented: $showPurchaseSuccessAlert
                )
                .zIndex(101)
            }
            
            if showPurchaseFailAlert {
                LackPopup(
                    title: "코인이 부족해요",
                    message: "충전하러 갈까요?",
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showPurchaseFailAlert = false
                        }
                    },
                    onConfirm: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showPurchaseFailAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            router.push(.coinCharge)
                        }
                    }
                )
                .zIndex(100)
            }
        }
    }
    
    func handleInvenExpandConfirm() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            invenExpandAlertScale = 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showInvenExpandAlert = false
            expandInventory()
        }
    }
}
