//
//  AcrylicPhotoEditedView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//  누끼 제거 결과 화면 + 애니메이션
//

import SwiftUI

struct AcrylicPhotoEditedView: View {
    // MARK: - Dependencies
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: AcrylicPhotoVM
    
    // MARK: - Animation States
    @State private var showRemovedBackground = false

    // 누끼 전 이미지 (배경 레이어) - 등장 애니메이션
    @State private var beforeImageScale: CGFloat = 0.3
    @State private var beforeImageOpacity: Double = 0.0

    // 누끼 후 이미지 (전경 레이어) - 전환 애니메이션
    @State private var afterImageScale: CGFloat = 2.2
    @State private var afterImageOpacity: Double = 0.0

    // 완료 체크마크 애니메이션
    @State private var showCheckmark = false
    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkOpacity: Double = 0.0

    // 배경 제거 실패 처리
    @State private var showFailureAlert = false
    @State private var isBackgroundRemovalFailed = false
    
    // MARK: - Constants
    private let imageMaxWidth: CGFloat = 350
    private let initialAppearDuration: Double = 1.6
    private let transitionDelay: Double = 2.0
    private let springResponse: Double = 2.5
    private let springDamping: Double = 0.3
    
    // MARK: - Body
    var body: some View {
        ZStack {
            imageTransitionView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: showCheckmark || showFailureAlert ? 15 : 0)
                .animation(.easeInOut(duration: 0.3), value: showCheckmark)
                .animation(.easeInOut(duration: 0.3), value: showFailureAlert)

            /// 누끼 완료 alert
            KeychyAlert(
                type: .checkmark,
                message: "배경 제거 완료!",
                isPresented: $showCheckmark
            )

            /// 배경 제거 실패 alert
            KeychyAlert(
                type: .fail,
                message: "다른 사진으로 다시 시도해 주세요.",
                isPresented: $showFailureAlert
            )
        }
        .toolbar {
            naivgationTitle
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startBackgroundRemoval()
        }
        .onDisappear {
            resetCheckmarkState()
        }
        .onChange(of: showFailureAlert) { _, isShowing in
            if !isShowing && isBackgroundRemovalFailed {
                handleBackToPhotoPicker()
            }
        }
    }
}

// MARK: - View Components
extension AcrylicPhotoEditedView {
    
    /// 네비 타이틀
    private var naivgationTitle: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            NavigationTitle(title: "누끼를 제거합니다!")
        }
    }
    
    /// 누끼 전→후 이미지 트랜지션 (레이어 효과)
    private var imageTransitionView: some View {
        ZStack {
            // 배경 레이어: 누끼 전 (흐림)
            beforeImageLayer
            
            // 전경 레이어: 누끼 후 (선명)
            if showRemovedBackground {
                afterImageLayer
            }
        }
        .padding(.bottom, 60)
    }
    
    /// 누끼 전 이미지 (배경 레이어)
    private var beforeImageLayer: some View {
        Image(uiImage: viewModel.croppedImage)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: imageMaxWidth)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(beforeImageScale)
            .opacity(beforeImageOpacity)
    }
    
    /// 누끼 후 이미지 (전경 레이어)
    private var afterImageLayer: some View {
        Image(uiImage: viewModel.removedBackgroundImage)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: imageMaxWidth)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .scaleEffect(afterImageScale)
            .opacity(afterImageOpacity)
    }
    
    // MARK: - Actions

    /// 다음 단계로 진행
    private func proceedToNextStep() {
        AcrylicPhotoVM.removeBackgroundAndCrop(from: viewModel.removedBackgroundImage) { croppedImage in
            if let croppedImage = croppedImage {
                viewModel.bodyImage = croppedImage
                router.push(.acrylicPhotoCustomizing)
            }
        }
    }

    /// 포토피커로 복귀
    private func handleBackToPhotoPicker() {
        viewModel.resetImageData()
        router.pop()
        router.pop()
    }
    
    /// 체크마크 상태 리셋 (뒤로가기 시)
    private func resetCheckmarkState() {
        showCheckmark = false
        checkmarkScale = 0.3
        checkmarkOpacity = 0.0
    }
    
    // MARK: - Animation Sequence
    /// 배경 제거 및 애니메이션 시퀀스 시작
    private func startBackgroundRemoval() {
        animateImageAppearance()
        performBackgroundRemoval()
    }
    
    /// 1단계: 원본 이미지 등장 애니메이션
    private func animateImageAppearance() {
        withAnimation(.easeOut(duration: initialAppearDuration)) {
            beforeImageScale = 1.0
            beforeImageOpacity = 1.0
        }
    }
    
    /// 2단계: 배경 제거 처리
    private func performBackgroundRemoval() {
        AcrylicPhotoVM.removeBackground(from: viewModel.croppedImage) { [self] result in
            if let result = result {
                viewModel.removedBackgroundImage = result
            } else {
                // 실패해도 원본 이미지로 애니메이션 진행
                viewModel.removedBackgroundImage = viewModel.croppedImage
                isBackgroundRemovalFailed = true
            }

            // 3단계로 진행 (성공/실패 모두)
            DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay) {
                animateImageTransition()
            }
        }
    }
    
    /// 3단계: 누끼 전→후 전환 애니메이션 (레이어 효과)
    private func animateImageTransition() {
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            // 배경 레이어: 흐려지기
            beforeImageScale = 1.0
            beforeImageOpacity = 0.3
            
            // 전경 레이어: 크게 등장 → 정상 크기
            afterImageOpacity = 1.0
            afterImageScale = 1.0
            
            showRemovedBackground = true
        }
        
        // 4단계: 전환 완료 후 햅틱 + 체크마크
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            triggerCompletionFeedback()
        }
    }
    
    /// 4단계: 완료 피드백 (햅틱 + 체크마크 + 자동 진행)
    private func triggerCompletionFeedback() {
        // 햅틱 두둑두둑ㅋㅋ일단넣어
        Haptic.impact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Haptic.impact()
        }

        if isBackgroundRemovalFailed {
            // 실패 alert 표시
            showFailureAlert = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }

            // 2.5초 후 포토피커로 복귀
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showFailureAlert = false
            }
        } else {
            // 성공 체크마크 애니메이션
            showCheckmark = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }

            // 2.5초 후 자동으로 다음 화면
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                proceedToNextStep()
            }
        }
    }
}

