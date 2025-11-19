//
//  PolaroidPreview.swift
//  Keychy
//
//  폴라로이드 템플릿 프리뷰
//

import SwiftUI

struct PolaroidPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: PolaroidVM

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                router.push(.polaroidCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}

#Preview {
    PolaroidPreview(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: PolaroidVM()
    )
    .environment(UserManager.shared)
}
