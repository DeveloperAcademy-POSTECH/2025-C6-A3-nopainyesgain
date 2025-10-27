//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopTab: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State private var arcylicPhotoVM: ArcylicPhotoVM?
    
    var body: some View {
        NavigationStack(path: $router.path) {
            WorkshopView(router: router)
                .navigationDestination(for: WorkshopRoute.self) { route in
                    switch route {

                    // MARK: - AcrylicPhoto
                    case .arcylicPhotoPreview:
                        ArcylicPhotoPreView(router: router, viewModel: getArcylicPhotoVM())
                    case .arcylicPhotoCrop:
                        ArcylicPhotoCropView(router: router, viewModel: getArcylicPhotoVM())
                    case .arcylicPhotoEdited:
                        ArcylicPhotoEditedView(router: router, viewModel: getArcylicPhotoVM())
                    case .arcylicPhotoCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getArcylicPhotoVM(),
                            navigationTitle: "아크릴 키링",
                            nextRoute: .arcylicPhotoInfoInput
                        )
                    case .arcylicPhotoInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getArcylicPhotoVM(),
                            navigationTitle: "정보 입력",
                            nextRoute: .arcylicPhotoComplete
                        )
                    case .arcylicPhotoComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getArcylicPhotoVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - 새로운 템플릿이 추가되면 여기에 루트를 지정해주면 됩니다.
                    }
                }
        }
        .tint(.black)
    }

    // MARK: - ViewModel Lazy Getters
    private func getArcylicPhotoVM() -> ArcylicPhotoVM {
        guard let viewModel = arcylicPhotoVM else {
            let newViewModel = ArcylicPhotoVM()
            arcylicPhotoVM = newViewModel
            return newViewModel
        }
        return viewModel
    }
}
