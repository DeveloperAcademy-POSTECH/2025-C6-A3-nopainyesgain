////
////  ClearSketchPreview.swift
////  Keychy
////
////  Created by Jini on 11/19/25.
////
//
//import SwiftUI
//
//struct ClearSketchPreview: View {
//    @Bindable var router: NavigationRouter<WorkshopRoute>
//    @State var viewModel: ClearSketchVM
//
//    var body: some View {
//        TemplatePreviewBody(
//            template: viewModel.template,
//            fetchTemplate: {
//                await viewModel.fetchTemplate()
//                await viewModel.fetchFrames()
//            },
//            onMake: {
//                router.push(.clearSketchCustomizing)
//            },
//            router: router
//        )
//        .swipeBackGesture(enabled: true)
//    }
//}
//
//#Preview {
//    ClearSketchPreview()
//}
