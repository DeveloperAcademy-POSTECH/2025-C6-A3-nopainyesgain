//
//  SpeechBubblePreview.swift
//  Keychy
//
//  Created by 길지훈 on 11/24/25.
//
//  말풍선 템플릿 프리뷰
//

import SwiftUI

struct SpeechBubblePreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: SpeechBubbleVM

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
                await viewModel.fetchFrames()
                await viewModel.fetchEffects()
            },
            onMake: {
                router.push(.speechBubbleCustomizing)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
