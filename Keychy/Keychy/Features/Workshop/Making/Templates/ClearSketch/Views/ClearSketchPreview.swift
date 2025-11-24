//
//  ClearSketchPreview.swift
//  Keychy
//
//  Created by Jini on 11/19/25.
//

import SwiftUI

struct ClearSketchPreview: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: ClearSketchVM
    @Environment(UserManager.self) private var userManager
    
    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: {
                await viewModel.fetchTemplate()
            },
            onMake: {
                router.push(.clearSketchDrawing)
            },
            router: router
        )
        .swipeBackGesture(enabled: false)
    }
}
