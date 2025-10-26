//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopTab: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State private var mkViewModel: MKViewModel?
    
    var body: some View {
        NavigationStack(path: $router.path) {
            WorkshopView(router: router)
                .navigationDestination(for: WorkshopRoute.self) { route in
                    switch route {

                    // MARK: - AcrylicPhoto
                    case .mkPreview:
                        MKPreviewView(router: router, viewModel: getMKViewModel())
                    case .mkPhotoCrop:
                        MKPhotoCropView(router: router, viewModel: getMKViewModel())
                    case .mkEditedPhoto:
                        MKEditedPhotoView(router: router, viewModel: getMKViewModel())
                    case .mkCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getMKViewModel(),
                            navigationTitle: "아크릴 키링",
                            nextRoute: .mkInfoInput
                        )
                    case .mkInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getMKViewModel(),
                            navigationTitle: "정보 입력",
                            nextRoute: .mkComplete
                        )
                    case .mkComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getMKViewModel(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - 새로운 템플릿이 추가되면 여기에 루트를 지정해주면 됩니다.
                    }
                }
        }
        .tint(.black)
    }

    // MARK: - ViewModel Lazy Getters
    private func getMKViewModel() -> MKViewModel {
        guard let viewModel = mkViewModel else {
            let newViewModel = MKViewModel()
            mkViewModel = newViewModel
            return newViewModel
        }
        return viewModel
    }
}
