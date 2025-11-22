//
//  TemplatePreviewComponents.swift
//  Keychy
//
//  Created by Rundo on 11/8/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Template Preview Body
/// 템플릿 프리뷰 body 전체 구조
struct TemplatePreviewBody: View {
    let template: KeyringTemplate?
    let fetchTemplate: () async -> Void
    let onMake: () -> Void
    var onPurchase: (() -> Void)? = nil
    var router: NavigationRouter<WorkshopRoute>? = nil

    @Environment(UserManager.self) private var userManager

    // 구매 관련 상태
    @State private var showPurchaseSheet = false
    @State private var purchasePopupScale: CGFloat = 0.3
    @State private var showPurchasingLoading = false
    @State private var showPurchaseSuccessAlert = false
    @State private var showPurchaseFailAlert = false
    @State private var purchaseFailScale: CGFloat = 0.3
    
    // 보관함 용량 관련
    @State private var showInvenFullAlert: Bool = false

    /// 템플릿 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let templateId = template?.id else { return false }
        return user.templates.contains(templateId)
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                // 프리뷰 이미지
                templatePreview
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    // 템플릿 정보
                    infoSection
                        .padding(.bottom, 40)
                        .frame(minHeight: 120, alignment: .top)
                    
                    // 액션 버튼
                    actionButton
                        .adaptiveBottomPadding()
                        .padding(.bottom, getBottomPadding(40) == 0 ? 40 : 0)
                }
                .padding(.horizontal, 34)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CustomNavigationBar {
                BackToolbarButton {
                    router?.pop()
                }
            } center: {
                Spacer()
            } trailing: {
                Spacer()
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .blur(radius: (showPurchasingLoading || showPurchaseSuccessAlert) ? 10 : 0)
        .animation(.easeInOut(duration: 0.3), value: (showPurchasingLoading || showPurchaseSuccessAlert))
        .toolbar(.hidden, for: .tabBar)
        .task {
            await fetchTemplate()
        }
        .overlay {
            ZStack(alignment: .center) {
                // 구매 확인 팝업
                if showPurchaseSheet {
                    Color.black20
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchasePopupScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseSheet = false
                            }
                        }

                    if let template {
                        PurchasePopup(
                            title: template.name,
                            myCoin: userManager.currentUser?.coin ?? 0,
                            price: template.workshopPrice,
                            scale: purchasePopupScale,
                            onConfirm: {
                                Task {
                                    await handlePurchase()
                                }
                            }
                        )
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }

                // 구매 중 로딩
                if showPurchasingLoading {
                    LoadingAlert(type: .short, message: nil)
                }

                // 구매 성공 알림
                if showPurchaseSuccessAlert {
                    KeychyAlert(
                        type: .checkmark,
                        message: "구매 완료!",
                        isPresented: $showPurchaseSuccessAlert
                    )
                }

                // TODO: - 구버전 Alert 사용중, Popup으로 전환 필요
                // 구매 실패 알림 (코인 부족)
                if showPurchaseFailAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    BangmarkAlert(
                        checkmarkScale: purchaseFailScale,
                        text: "코인이 부족해요",
                        cancelText: "취소",
                        confirmText: "충전하기",
                        onCancel: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseFailScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseFailAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseFailScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseFailAlert = false
                                router?.push(.coinCharge)
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                
                if showInvenFullAlert {
                    InvenLackPopup(isPresented: $showInvenFullAlert)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - TemplatePreviewBody Extensions
extension TemplatePreviewBody {
    /// 템플릿 프리뷰 이미지
    private var templatePreview: some View {
        VStack {
            Spacer()
            
            if let template {
                ItemDetailImage(itemURL: template.previewURL)
                    .scaledToFit()
                    .frame(width: 386, height: 386)
            } else {
                ProgressView()
            }
        }
        .frame(maxHeight: 500)
    }

    /// 템플릿 정보 섹션
    private var infoSection: some View {
        Group {
            if let template {
                ItemDetailInfoSection(item: template)
            } else {
                Text("템플릿 정보 없음")
            }
        }
    }

    /// 액션 버튼 (만들기/구매)
    private var actionButton: some View {
        Group {
            if let template {
                KeyringTemplateActionButton(
                    template: template,
                    isOwned: isOwned,
                    onMake: checkInventoryAndMake,
                    onPurchase: onPurchase ?? {
                        showPurchaseSheet = true
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                            purchasePopupScale = 1.0
                        }
                    }
                )
            } else {
                ProgressView()
            }
        }
    }

    /// 구매 처리
    private func handlePurchase() async {
        guard let template = template else { return }

        // 팝업 닫기 애니메이션
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                purchasePopupScale = 0.3
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        await MainActor.run {
            showPurchaseSheet = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        // 로딩 시작
        await MainActor.run {
            showPurchasingLoading = true
        }

        // ItemPurchaseManager를 통해 구매 처리
        let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(template, userManager: userManager)

        // 로딩 종료
        await MainActor.run {
            showPurchasingLoading = false
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        switch result {
        case .success:
            // 성공 시 성공 알림 표시
            showPurchaseSuccessAlert = true

        case .insufficientCoins:
            // 코인 부족 시 실패 알림 표시
            showPurchaseFailAlert = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                purchaseFailScale = 1.0
            }

        case .failed(let message):
            // 기타 실패 시 에러 출력
            print("구매 실패: \(message)")
        }
    }
    
    /// 보관함 용량 체크 후 만들기 실행
    private func checkInventoryAndMake() {
        guard let userId = userManager.currentUser?.id else { return }
        
        // CollectionViewModel의 용량 체크 메서드 사용
        let collectionVM = CollectionViewModel()
        collectionVM.checkInventoryCapacity(userId: userId) { hasSpace in
            DispatchQueue.main.async {
                if hasSpace {
                    // 보관함에 여유 있음 -> onMake 실행
                    self.onMake()
                } else {
                    // 보관함 가득 참 -> 알럿 표시
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showInvenFullAlert = true
                    }
                }
            }
        }
    }
}
