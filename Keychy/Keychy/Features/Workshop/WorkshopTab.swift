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
    @State private var neonSignVM: NeonSignVM?
    @State private var polaroidVM: PolaroidVM?
    @State private var workshopViewModel = WorkshopViewModel(userManager: UserManager.shared)

    var body: some View {
        NavigationStack(path: $router.path) {
            WorkshopView(router: router, viewModel: workshopViewModel)
                .navigationDestination(for: WorkshopRoute.self) { route in
                    switch route {

                    // MARK: - 공통 프리뷰
                    case .workshopPreview(let item):
                        if let template = item.base as? KeyringTemplate {
                            WorkshopPreview(router: router, viewModel: workshopViewModel, item: template)
                        } else if let background = item.base as? Background {
                            WorkshopPreview(router: router, viewModel: workshopViewModel, item: background)
                        } else if let carabiner = item.base as? Carabiner {
                            WorkshopPreview(router: router, viewModel: workshopViewModel, item: carabiner)
                        } else if let particle = item.base as? Particle {
                            WorkshopPreview(router: router, viewModel: workshopViewModel, item: particle)
                        } else if let sound = item.base as? Sound {
                            WorkshopPreview(router: router, viewModel: workshopViewModel, item: sound)
                        }
                    
                    // MARK: - 내 창고뷰
                    case .myItems:
                        MyItemsView(router: router)
                    
                    // MARK: - 재화 구매뷰
                    case .coinCharge:
                        CoinChargeView(
                            router: router
                        )

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
                            nextRoute: .acrylicPhotoInfoInput
                        )
                    case .acrylicPhotoInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getAcrylicPhotoVM(),
                            nextRoute: .acrylicPhotoComplete
                        )
                    case .acrylicPhotoComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getAcrylicPhotoVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - NeonSign
                    case .NeonSignPreView:
                        NeonSignPreView(router: router, viewModel: getNeonSignVM())
                    case .neonSignCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getNeonSignVM(),
                            nextRoute: .neonSignInfoInput
                        )
                    case .neonSignInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getNeonSignVM(),
                            nextRoute: .neonSignComplete
                        )
                    case .neonSignComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getNeonSignVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - Polaroid
                    case .polaroidPreview:
                        PolaroidPreview(router: router, viewModel: getPolaroidVM())
                    case .polaroidCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getPolaroidVM(),
                            nextRoute: .polaroidInfoInput
                        )
                    case .polaroidInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getPolaroidVM(),
                            nextRoute: .polaroidComplete
                        )
                    case .polaroidComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getPolaroidVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

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

    private func getNeonSignVM() -> NeonSignVM {
        guard let viewModel = neonSignVM else {
            let newViewModel = NeonSignVM()
            neonSignVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getPolaroidVM() -> PolaroidVM {
        guard let viewModel = polaroidVM else {
            let newViewModel = PolaroidVM()
            polaroidVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    // MARK: - ViewModel Reset
    func resetAcrylicPhotoVM() {
        acrylicPhotoVM = nil
    }

    func resetNeonSignVM() {
        neonSignVM = nil
    }

    func resetPolaroidVM() {
        polaroidVM = nil
    }
}
