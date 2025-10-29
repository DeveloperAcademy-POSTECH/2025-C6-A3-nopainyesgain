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

    // MARK: - Constants
    private let imageMaxWidth: CGFloat = 300
    private let initialAppearDuration: Double = 1.6
    private let transitionDelay: Double = 2.0
    private let springResponse: Double = 2.5
    private let springDamping: Double = 0.3

    // MARK: - Body
    var body: some View {
        ZStack {
            VStack {
                imageTransitionView
                nextStepButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.isProcessing {
                loadingOverlay
            }
        }
        .navigationTitle("편집 완료!")
        .onAppear {
            startBackgroundRemoval()
        }
    }

    // MARK: - Components
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

    /// 다음 단계 버튼
    private var nextStepButton: some View {
        Button {
            proceedToNextStep()
        } label: {
            Text("편집하러 가기")
                .foregroundStyle(Color.primary)
                .padding(.vertical, 16)
                .padding(.horizontal, 50)
        }
        .disabled(viewModel.isProcessing)
        .padding(.bottom, 60)
        .opacity(beforeImageOpacity)
    }

    /// 로딩 오버레이
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("키링 생성중...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }

    // MARK: - Actions

    /// 다음 단계로 진행
    private func proceedToNextStep() {
        viewModel.isProcessing = true

        AcrylicPhotoVM.removeBackgroundAndCrop(from: viewModel.removedBackgroundImage) { croppedImage in
            viewModel.isProcessing = false

            if let croppedImage = croppedImage {
                viewModel.bodyImage = croppedImage
                router.push(.acrylicPhotoCustomizing)
            } else {
                viewModel.errorMessage = "이미지 처리에 실패했습니다."
            }
        }
    }

    // MARK: - Animation Sequence

    /// 배경 제거 및 애니메이션 시퀀스 시작
    private func startBackgroundRemoval() {
        viewModel.isProcessing = true
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
            viewModel.removedBackgroundImage = result ?? viewModel.croppedImage
            viewModel.isProcessing = false

            // 3단계로 진행
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
    }
}
