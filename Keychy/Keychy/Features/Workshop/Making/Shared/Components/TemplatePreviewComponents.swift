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
    @State private var showPurchaseSuccessAlert = false
    @State private var purchaseSuccessScale: CGFloat = 0.3
    @State private var showPurchaseFailAlert = false
    @State private var purchaseFailScale: CGFloat = 0.3

    /// 템플릿 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let templateId = template?.id else { return false }
        return user.templates.contains(templateId)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // 프리뷰 이미지
                ItemDetailImage(itemURL: template?.previewURL ?? "")
                    .scaledToFit()
                    .frame(maxWidth: .infinity)

                Spacer()

                // 템플릿 정보
                infoSection
            }
            .padding(.bottom, 120)

            // 액션 버튼
            actionButton
        }
        .padding(.horizontal, 35)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await fetchTemplate()
        }
        .task(id: template?.id) {
            // 무료 템플릿이면 자동으로 소유권 추가
            if let template = template,
               template.isFree,
               !isOwned,
               let templateId = template.id,
               let userId = userManager.currentUser?.id {
                do {
                    try await Firestore.firestore()
                        .collection("User")
                        .document(userId)
                        .updateData([
                            "templates": FieldValue.arrayUnion([templateId])
                        ])
                } catch {
                    print(" Failed to add template \(templateId): \(error.localizedDescription)")
                }
            }
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

                // 구매 성공 알림
                if showPurchaseSuccessAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    BangmarkAlert(
                        checkmarkScale: purchaseSuccessScale,
                        text: "구매 완료!",
                        cancelText: "닫기",
                        confirmText: "확인",
                        onCancel: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseSuccessScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseSuccessAlert = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                purchaseSuccessScale = 0.3
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showPurchaseSuccessAlert = false
                            }
                        }
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }

                // 구매 실패 알림 (코인 부족)
                if showPurchaseFailAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {}

                    BangmarkAlert(
                        checkmarkScale: purchaseFailScale,
                        text: "열쇠가 부족해요",
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
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - TemplatePreviewBody Extensions
extension TemplatePreviewBody {
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
                    onMake: onMake,
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

        // ItemPurchaseManager를 통해 구매 처리
        let result = await ItemPurchaseManager.shared.purchaseWorkshopItem(template, userManager: userManager)

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

        switch result {
        case .success:
            // 성공 시 성공 알림 표시
            showPurchaseSuccessAlert = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                purchaseSuccessScale = 1.0
            }

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
}
