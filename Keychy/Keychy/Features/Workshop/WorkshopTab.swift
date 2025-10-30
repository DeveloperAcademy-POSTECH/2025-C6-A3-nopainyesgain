//
//  HomeTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct WorkshopTab: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State private var acrylicPhotoVM: AcrylicPhotoVM?
    
    var body: some View {
        NavigationStack(path: $router.path) {
            WorkshopView(router: router)
                .navigationDestination(for: WorkshopRoute.self) { route in
                    switch route {
                        
                    case .myTemplate:
                        MyTemplateView()

                    // MARK: - AcrylicPhoto
                    case .acrylicPhotoPreview:
                        AcrylicPhotoPreView(router: router, viewModel: getAcrylicPhotoVM())
                    case .acrylicPhotoCrop:
                        AcrylicPhotoCropView(router: router, viewModel: getAcrylicPhotoVM())
                    case .acrylicPhotoEdited:
                        AcrylicPhotoEditedView(router: router, viewModel: getAcrylicPhotoVM())
                    case .acrylicPhotoCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getAcrylicPhotoVM(),
                            navigationTitle: "아크릴 키링",
                            nextRoute: .acrylicPhotoInfoInput
                        )
                    case .acrylicPhotoInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getAcrylicPhotoVM(),
                            navigationTitle: "정보 입력",
                            nextRoute: .acrylicPhotoComplete
                        )
                    case .acrylicPhotoComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getAcrylicPhotoVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )
                    case .coinCharge:
                        CoinChargeView(
                            router: router
                        )

                    // MARK: - TextPhoto
                    case .TextPhotoPreView:
                        TextPhotoPreView()
                    
                    // MARK: - 새로운 템플릿이 추가되면 여기에 루트를 지정해주면 됩니다.
                    }
                }
        }
        .tint(.black)
    }

    // MARK: - ViewModel Lazy Getters
    private func getAcrylicPhotoVM() -> AcrylicPhotoVM {
        guard let viewModel = acrylicPhotoVM else {
            let newViewModel = AcrylicPhotoVM()
            acrylicPhotoVM = newViewModel
            return newViewModel
        }
        return viewModel
    }
}
