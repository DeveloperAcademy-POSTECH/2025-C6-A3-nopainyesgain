//
//  BundleEditView+Alert.swift
//  Keychy
//
//  Created by 김서현 on 1/13/26.
//

import SwiftUI

extension BundleEditView {
    var alertContent: some View {
        Group {
            if showChangeCarabinerAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showChangeCarabinerAlert = false
                        }
                    }
                VStack {
                    Spacer()
                    CarabinerChangePopup(
                        title: "카라비너를 변경하시겠어요?",
                        message: "새 카라비너로 변경하면\n현재 뭉치에 걸린 키링들이 모두 해제돼요.",
                        onCancel: {
                            selectCarabiner = nil
                            showChangeCarabinerAlert = false
                        },
                        onConfirm: {
                            Task { @MainActor in
                                // 편집 중 로컬 상태만 변경 (Firestore에 쓰지 않음)
                                
                                // 1) UI 오버레이/선택 상태 초기화
                                selectedPosition = 0
                                
                                // 2) 키링 데이터와 선택 목록을 즉시 비우기
                                keyringDataList = []
                                selectedKeyrings.removeAll()
                                keyringOrder.removeAll()
                                
                                // 3) 새 카라비너 적용
                                newSelectedCarabiner = selectCarabiner
                                
                                // 4) 빈 상태를 씬/리스트에 반영
                                updateKeyringDataList()
                                
                                // 5) 씬 강제 리프레시로 남은 잔상 제거
                                sceneRefreshId = UUID()
                                
                                // 6) 알럿 닫기
                                showChangeCarabinerAlert = false
                            }
                        }
                    )
                    .padding(.horizontal, 51)
                    Spacer()
                }
            }
            
            // 구매 성공 Alert
            if showPurchaseSuccessAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        Task {
                            await saveBundleChanges()
                            await MainActor.run {
                                showPurchaseSuccessAlert = false
                                purchasesSuccessScale = 0.3
                            }
                        }
                    }
                
                KeychyAlert(type: .checkmark, message: "구매가 완료되었어요!", isPresented: $showPurchaseSuccessAlert)
                    .zIndex(101)
            }
            
            // 구매 실패 Alert
            if showPurchaseFailAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                    }
                
                PurchaseFailAlert(
                    checkmarkScale: purchaseFailScale,
                    onCancel: {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                    },
                    onCharge: {
                        showPurchaseFailAlert = false
                        purchaseFailScale = 0.3
                        saveCurrentSelection()
                        router.push(.coinCharge)
                    }
                )
                .padding(.horizontal, 51)
            }
        }
    }
}
