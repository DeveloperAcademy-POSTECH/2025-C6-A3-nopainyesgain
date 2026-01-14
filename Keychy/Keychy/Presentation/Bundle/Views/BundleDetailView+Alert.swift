//
//  BundleDetailView+Alert.swift
//  Keychy
//
//  Created by 김서현 on 1/8/26.
//

import SwiftUI

extension BundleDetailView {
    
    private var shouldShowAlertOverlay: Bool {
        !isSceneReady
        || uiState.showChangeMainBundleAlert
        || uiState.isMainBundleChange
        || uiState.isCapturing
        || uiState.showDeleteAlert
        || uiState.showDeleteCompleteToast
        || uiState.showAlreadyMainBundleToast
    }
    
    @ViewBuilder
    var alertOverlays: some View {
        if shouldShowAlertOverlay {
            Color.black20
                .ignoresSafeArea()
            
            LoadingAlert(type: .longWithKeychy, message: "뭉치를 불러오고 있어요")
                .zIndex(200)
                .opacity(isSceneReady ? 0 : 1)
            
            changeMainBundleAlert
                .opacity(uiState.showChangeMainBundleAlert ? 1 : 0)
                .padding(.horizontal, 51)
                .position(x: screenWidth/2, y: screenHeight/2)
            
            KeychyAlert(type: .checkmark, message: "대표 뭉치가 변경되었어요!", isPresented: $uiState.isMainBundleChange)
                .zIndex(200)
            
            KeychyAlert(type: .imageSave, message: "이미지가 저장되었어요!", isPresented: $uiState.isCapturing)
                .zIndex(200)
            
            // 뭉치 삭제 알럿
            if uiState.showDeleteAlert {
                if let bundle = bundleVM.selectedBundle {
                    DeletePopup(
                        title: "[\(bundle.name)]\n삭제하시겠어요?",
                        message: "삭제한 뭉치는 복구할 수 없습니다.",
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                uiState.showDeleteAlert = false
                            }
                        },
                        onConfirm: {
                            Task {
                                await deleteBundle()
                            }
                        }
                    )
                    .position(x: screenWidth/2, y: screenHeight/2)
                    .zIndex(200)
                }
            }
            // 뭉치 삭제 완료 토스트
            else if uiState.showDeleteCompleteToast {
                DeleteCompletePopup(isPresented: $uiState.showDeleteCompleteToast)
                    .zIndex(200)
                    .position(x: screenWidth/2, y: screenHeight/2)
            }
            
            // 이미 대표 뭉치로 설정 되었다는 토스트 - 대표뭉치 아이콘 한 번 더 클릭 시 뜸
            alreadyMainBundleToast
                .zIndex(200)
                .opacity(uiState.showAlreadyMainBundleToast ? 1 : 0)
                .padding(.horizontal, 51)
                .position(x: screenWidth/2, y: screenHeight/2)
        }
    }
    
    // 대표 뭉치 변경 알럿을 띄우는 뷰
    private var changeMainBundleAlert: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(.bangMark)
                    .padding(.vertical, 4)
                
                Text("대표 뭉치를 변경할까요?")
                    .typography(.suit20B)
                    .foregroundStyle(.black100)
                Text("선택한 뭉치가 홈에 걸려요.")
                    .typography(.suit15R)
                    .foregroundStyle(.black100)
            }
            .padding(8)
            
            // 버튼 영역
            HStack(spacing: 16) {
                Button {
                    uiState.showChangeMainBundleAlert = false
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.black10)
                
                Button {
                    // 네트워크 체크
                    guard NetworkManager.shared.isConnected else {
                        uiState.showChangeMainBundleAlert = false
                        ToastManager.shared.show()
                        return
                    }
                    
                    bundleVM.updateBundleMainStatus(bundle: bundleVM.selectedBundle!, isMain: true) { _ in }
                    uiState.showChangeMainBundleAlert = false
                    uiState.isMainBundleChange = true
                } label: {
                    Text("확인")
                        .typography(.suit17SB)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.main500)
            }
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 34))
        .frame(maxWidth: .infinity)
    }
    
    // 이미 대표 뭉치로 설정 되었음을 알리는 토스트뷰
    private var alreadyMainBundleToast: some View {
        Text("이미 대표 뭉치로 설정되어 있어요")
            .typography(.suit17SB)
            .foregroundColor(.black100)
            .frame(maxWidth: .infinity)
            .frame(height: 73)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
            .transition(.scale.combined(with: .opacity))
    }
}
