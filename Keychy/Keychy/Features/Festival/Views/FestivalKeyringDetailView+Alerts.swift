////
////  FestivalKeyringDetailView+Alerts.swift
////  Keychy
////
////  Created by Jini on 11/24/25.
////
//
//import SwiftUI
//
//// MARK: - 알럿/팝업 관련
//extension FestivalKeyringDetailView {
//    @ViewBuilder
//    var alertOverlays: some View {
//        
//        if showCopyAlert || showCopyingAlert || showCopyCompleteAlert || showCopyLackAlert || showInvenFullAlert {
//            copyAlertOverlay
//        }
//        
//        if showPackageAlert || showPackingAlert {
//            packageAlertOverlay
//        }
//    }
//    
//    // MARK: - Copy Alerts
//    private var copyAlertOverlay: some View {
//        
//        ZStack {
//            Color.black20
//                .ignoresSafeArea()
//                .zIndex(99)
//            
//            if showCopyAlert {
//                CopyPopup(
//                    myCopyPass: viewModel.copyVoucher,
//                    onCancel: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            showCopyAlert = false
//                        }
//                    },
//                    onConfirm: {
//                        handleCopyConfirm()
//                    }
//                )
//                .transition(.scale.combined(with: .opacity))
//                .zIndex(100)
//            }
//            
//            if showCopyingAlert {
//                LoadingAlert(type: .short, message: nil)
//                    .zIndex(101)
//            }
//            
//            if showCopyCompleteAlert {
//                KeychyAlert(
//                    type: .copy,
//                    message: "키링이 복사되었어요!",
//                    isPresented: $showCopyCompleteAlert
//                )
//                .zIndex(101)
//            }
//            
//            if showCopyLackAlert {
//                LackPopup(
//                    title: "복사권이 부족해요",
//                    message: "충전하러 갈까요?",
//                    onCancel: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            showCopyLackAlert = false
//                        }
//                    },
//                    onConfirm: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            showCopyLackAlert = false
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                            isSheetPresented = false
//                            
//                            router.push(.coinCharge)
//                        }
//                    }
//                )
//                .zIndex(100)
//            }
//            
//            if showInvenFullAlert {
//                InvenLackPopup(isPresented: $showInvenFullAlert)
//                    .zIndex(100)
//            }
//        }
//    }
//    
//    func handleCopyConfirm() {
//        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
//            showCopyAlert = false
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//            guard let uid = UserDefaults.standard.string(forKey: "userUID") else {
//                print("UID를 찾을 수 없습니다")
//                return
//            }
//            
//            // 1. 복사권 개수 확인
//            if self.viewModel.copyVoucher <= 0 {
//                print("복사권 부족")
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                    self.showCopyLackAlert = true
//                }
//                return
//            }
//            
//            // 2. 인벤토리 용량 확인
//            self.viewModel.checkInventoryCapacity(userId: uid) { hasSpace in
//                DispatchQueue.main.async {
//                    if !hasSpace {
//                        // 보관함 가득 찬 경우
//                        print("보관함 가득 찬")
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            self.showInvenFullAlert = true
//                        }
//                        return
//                    }
//                    
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                        self.showCopyingAlert = true
//                    }
//                    
//                    // 3. 복사권 있고, 인벤토리 여유 있음 -> 복사 진행
//                    self.viewModel.copyKeyring(uid: uid, keyring: self.keyring) { success, newKeyringId in
//                        DispatchQueue.main.async {
//                            self.showCopyingAlert = false
//                            
//                            if success {
//                                print("키링 복사 성공")
//                                
//                                // 복사권 개수 새로고침
//                                self.refreshCopyVoucher()
//                                
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                                        self.showCopyCompleteAlert = true
//                                    }
//                                }
//                            } else {
//                                print("키링 복사 실패")
//                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                                    self.showCopyLackAlert = true
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Package Alerts
//    private var packageAlertOverlay: some View {
//        ZStack {
//            Color.black20
//                .ignoresSafeArea()
//                .zIndex(99)
//            
//            if showPackageAlert {
//                PackagePopup(
//                    onCancel: {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            showPackageAlert = false
//                        }
//                    },
//                    onConfirm: {
//                        //handlePackageConfirm()
//                    }
//                )
//                .transition(.scale.combined(with: .opacity))
//                .zIndex(100)
//            }
//            
//            if showPackingAlert {
//                LoadingAlert(
//                    type: .longWithPresent,
//                    message: "선물 포장 중.."
//                )
//                .zIndex(101)
//            }
//        }
//    }
//    
//    func handlePackingComplete() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            isSheetPresented = false
//            
//            //router.push(.packageCompleteView(keyring: keyring, postOffice: postOfficeId))
//        }
//    }
//}
