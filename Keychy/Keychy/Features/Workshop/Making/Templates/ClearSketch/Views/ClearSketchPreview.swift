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
    @State private var showGuide = false
    @State private var hasAppearedBefore = false
    @State private var capturedImage: UIImage?
    
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
