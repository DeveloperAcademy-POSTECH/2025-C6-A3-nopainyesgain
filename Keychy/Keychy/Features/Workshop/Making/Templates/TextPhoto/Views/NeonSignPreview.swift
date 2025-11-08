//
//  NeonSignPreView.swift
//  Keychy
//
//  Created by rundo on 10/29/25.
//

import SwiftUI

struct NeonSignPreView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: NeonSignVM
    @Environment(UserManager.self) private var userManager

    /// 템플릿 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let templateId = viewModel.template?.id else { return false }
        return user.templates.contains(templateId)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                keyringPreview
                Spacer()
                keyringInfo
            }
            .padding(.bottom, 120)

            makeBtn
        }
        .padding(.horizontal, 35)
        .toolbar(.hidden, for: .tabBar)
        .task {
            // 템플릿 데이터 가져오기
            await viewModel.fetchTemplate()
        }
    }
}

// MARK: - Keyring Preview Section
extension NeonSignPreView {
    private var keyringPreview: some View {
        TemplatePreviewImageSection(
            previewURL: viewModel.template?.previewURL ?? ""
        )
    }
}

// MARK: - Info Section
extension NeonSignPreView {
    private var keyringInfo: some View {
        TemplatePreviewInfoSection(template: viewModel.template)
    }
}

// MARK: - Action Button Section
extension NeonSignPreView {
    private var makeBtn: some View {
        TemplatePreviewActionButton(
            template: viewModel.template,
            isOwned: isOwned,
            onMake: {
                // 바로 커스터마이징 화면으로 이동
                router.push(.neonSignCustomizing)
            },
            onPurchase: {
                // TODO: 구매 로직 구현
                if let template = viewModel.template {
                    print("구매: \(template.name) - \(template.workshopPrice) 코인")
                }
            }
        )
    }
}

#Preview {
    NeonSignPreView(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: NeonSignVM()
    )
    .environment(UserManager.shared)
}
