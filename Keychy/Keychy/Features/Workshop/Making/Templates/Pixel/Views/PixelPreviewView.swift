//
//  PixelPreviewView.swift
//  Keychy
//
//  Created by 길지훈 on 11/22/25.
//

import SwiftUI

struct PixelPreviewView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: PixelVM
    @Environment(UserManager.self) private var userManager

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                router.push(.pixelDraw)
            },
            router: router
        )
        .swipeBackGesture(enabled: true)
    }
}
