//
//  TemplatePreviewComponents.swift
//  Keychy
//
//  Created by Claude on 11/8/25.
//

import SwiftUI

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

// MARK: - Ownership Helper
/// 템플릿 소유 여부 확인 헬퍼
extension View {
    /// 템플릿 소유 여부 확인
    func isTemplateOwned(templateId: String?, userManager: UserManager) -> Bool {
        guard let user = userManager.currentUser,
              let templateId = templateId else { return false }
        return user.templates.contains(templateId)
    }
}
