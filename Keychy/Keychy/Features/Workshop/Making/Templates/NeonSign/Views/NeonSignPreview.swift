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
    var showDeleteButton: Bool = false

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                router.push(.neonSignCustomizing)
            },
            router: router,
            showDeleteButton: showDeleteButton
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
