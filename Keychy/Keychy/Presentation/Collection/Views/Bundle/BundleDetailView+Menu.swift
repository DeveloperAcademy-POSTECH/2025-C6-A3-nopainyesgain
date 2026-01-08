//
//  BundleDetailView+Menu.swift
//  Keychy
//
//  Created by 김서현 on 1/8/26.
//

import SwiftUI

extension BundleDetailView {
    @ViewBuilder
    
    // 우측 상단 ... 버튼 눌렀을 때 뜨는 메뉴 시트
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
            
            if let bundle = viewModel.selectedBundle {
                BundleMenu(
                    position: menuPosition,
                    onNameEdit: {
                        // 네트워크 체크
                        guard NetworkManager.shared.isConnected else {
                            showMenu = false
                            ToastManager.shared.show()
                            return
                        }
                        
                        showMenu = false
                        isNavigatingDeeper = true
                        router.push(.bundleNameEditView)
                    },
                    onEdit: {
                        // 네트워크 체크
                        guard NetworkManager.shared.isConnected else {
                            showMenu = false
                            ToastManager.shared.show()
                            return
                        }
                        
                        showMenu = false
                        isNavigatingDeeper = true
                        router.push(.bundleEditView)
                    },
                    onDelete: {
                        // 네트워크 체크
                        guard NetworkManager.shared.isConnected else {
                            showMenu = false
                            ToastManager.shared.show()
                            return
                        }
                        
                        showMenu = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDeleteAlert = true
                        }
                    },
                    isMain: bundle.isMain
                )
                .zIndex(50)
            }
        }
    }
    
}
