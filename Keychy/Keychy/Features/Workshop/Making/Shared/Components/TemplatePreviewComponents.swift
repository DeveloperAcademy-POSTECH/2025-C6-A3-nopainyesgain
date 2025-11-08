//
//  TemplatePreviewComponents.swift
//  Keychy
//
//  Created by Claude on 11/8/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Preview Layout
/// 템플릿 프리뷰 전체 레이아웃
struct TemplatePreviewLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: spacing) {
                Spacer()
                content
                Spacer()
            }
            .padding(.bottom, 120)
        }
        .padding(.horizontal, 35)
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Preview Image Section
/// 템플릿 프리뷰 이미지 섹션
struct TemplatePreviewImageSection: View {
    let previewURL: String

    var body: some View {
        ItemDetailImage(itemURL: previewURL)
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview Info Section
/// 템플릿 프리뷰 정보 섹션 (이름, 설명, 태그 등)
struct TemplatePreviewInfoSection: View {
    let template: KeyringTemplate?

    var body: some View {
        if let template {
            ItemDetailInfoSection(item: template)
        } else {
            Text("템플릿 정보 없음")
        }
    }
}

// MARK: - Preview Action Button
/// 템플릿 프리뷰 액션 버튼 (만들기/구매)
struct TemplatePreviewActionButton: View {
    let template: KeyringTemplate?
    let isOwned: Bool
    let onMake: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        Group {
            if let template {
                KeyringTemplateActionButton(
                    template: template,
                    isOwned: isOwned,
                    onMake: onMake,
                    onPurchase: onPurchase
                )
            } else {
                ProgressView()
            }
        }
    }
}

// MARK: - Auto Own Free Template Modifier
/// 무료 템플릿 자동 소유 처리
struct AutoOwnFreeTemplateModifier: ViewModifier {
    let template: KeyringTemplate?
    let isOwned: Bool
    @Environment(UserManager.self) private var userManager

    func body(content: Content) -> some View {
        content
            .task(id: template?.id) {
                // 무료 템플릿이면 자동으로 소유권 추가
                if let template = template,
                   template.isFree,
                   !isOwned,
                   let templateId = template.id,
                   let userId = userManager.currentUser?.id {
                    await addTemplateOwnership(userId: userId, templateId: templateId)
                }
            }
    }

    /// Firestore에 템플릿 소유권 추가
    private func addTemplateOwnership(userId: String, templateId: String) async {
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

extension View {
    /// 무료 템플릿 자동 소유 처리
    func autoOwnFreeTemplate(
        template: KeyringTemplate?,
        isOwned: Bool
    ) -> some View {
        modifier(AutoOwnFreeTemplateModifier(
            template: template,
            isOwned: isOwned
        ))
    }
}
