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

    @Environment(UserManager.self) private var userManager

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
                        print("구매: \(template.name) - \(template.workshopPrice) 코인")
                    }
                )
            } else {
                ProgressView()
            }
        }
    }
}
