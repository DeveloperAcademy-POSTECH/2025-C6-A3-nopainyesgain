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
    @State private var clearSketchVM: ClearSketchVM?
    @State private var pixelKeyringVM: PixelVM?
    @State private var speechBubbleVM: SpeechBubbleVM?
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
                        
                    // MARK: - Clear Sketch
                    case .clearSketchPreview:
                        ClearSketchPreview(router: router, viewModel: getClearSketchVM())
                    case .clearSketchDrawing:
                        ClearSketchDrawingView(router: router, viewModel: getClearSketchVM())
                    case .clearSketchCrop:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getClearSketchVM(),
                            nextRoute: .clearSketchCustomizing
                        )
                    case .clearSketchCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getClearSketchVM(),
                            nextRoute: .clearSketchInfoInput
                        )
                    case .clearSketchInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getClearSketchVM(),
                            nextRoute: .clearSketchComplete
                        )
                    case .clearSketchComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getClearSketchVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - PixelKeyring
                    case .pixelPreview:
                        PixelPreviewView(router: router, viewModel: getPixelKeyringVM())
                    case .pixelDraw:
                        PixelDrawView(router: router, viewModel: getPixelKeyringVM())
                    case .pixelCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getPixelKeyringVM(),
                            nextRoute: .pixelInfoInput
                        )
                    case .pixelInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getPixelKeyringVM(),
                            nextRoute: .pixelComplete
                        )
                    case .pixelComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getPixelKeyringVM(),
                            navigationTitle: "키링이 완성되었어요!"
                        )

                    // MARK: - SpeechBubble
                    case .speechBubblePreview:
                        // TODO: Issue #2에서 SpeechBubblePreview 뷰 생성 후 연결
                        EmptyView()
                    case .speechBubbleCustomizing:
                        KeyringCustomizingView(
                            router: router,
                            viewModel: getSpeechBubbleVM(),
                            nextRoute: .speechBubbleInfoInput
                        )
                    case .speechBubbleInfoInput:
                        KeyringInfoInputView(
                            router: router,
                            viewModel: getSpeechBubbleVM(),
                            nextRoute: .speechBubbleComplete
                        )
                    case .speechBubbleComplete:
                        KeyringCompleteView(
                            router: router,
                            viewModel: getSpeechBubbleVM(),
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
    
    private func getClearSketchVM() -> ClearSketchVM {
        guard let viewModel = clearSketchVM else {
            let newViewModel = ClearSketchVM()
            clearSketchVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getPixelKeyringVM() -> PixelVM {
        guard let viewModel = pixelKeyringVM else {
            let newViewModel = PixelVM()
            pixelKeyringVM = newViewModel
            return newViewModel
        }
        return viewModel
    }

    private func getSpeechBubbleVM() -> SpeechBubbleVM {
        guard let viewModel = speechBubbleVM else {
            let newViewModel = SpeechBubbleVM()
            speechBubbleVM = newViewModel
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

    func resetClearSketchVM() {
        clearSketchVM = nil
    }

    func resetPixelKeyringVM() {
        pixelKeyringVM = nil
    }

    func resetSpeechBubbleVM() {
        speechBubbleVM = nil
    }
}
