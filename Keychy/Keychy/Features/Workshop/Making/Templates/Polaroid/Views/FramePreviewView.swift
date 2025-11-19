//
//  FramePreviewView.swift
//  Keychy
//
//  폴라로이드 템플릿 프레임 미리보기 뷰 (중앙 씬 영역)
//

import SwiftUI
import PhotosUI
import NukeUI

struct FramePreviewView: View {
    @Bindable var viewModel: PolaroidVM
    let onSceneReady: () -> Void

    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showEditButton = false

    // 제스처 임시 값 (제스처 중에만 사용)
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var currentOffset: CGSize = .zero

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                // 프레임 + 사진 영역 (아래)
                VStack {
                    Spacer()
                        .frame(height: 125)

                    ZStack(alignment: .bottom) {
                        // 1. 선택된 사진 (맨 아래)
                        if let photoImage = viewModel.selectedPhotoImage {
                            ZStack {
                                Image(uiImage: photoImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 214, height: 267)
                                    .scaleEffect(finalScale)
                                    .rotationEffect(finalRotation)
                                    .offset(finalOffset)
                                    .clipped()  // frame 밖으로 나간 부분 잘라내기
                                    .padding(.bottom, 20)
                                    .contentShape(Rectangle())
                                    .gesture(photoGestures)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showEditButton.toggle()
                                        }
                                    }

                                // 편집 버튼 (사진 탭 시 표시)
                                if showEditButton {
                                    Button {
                                        showPhotoPicker = true
                                        showEditButton = false
                                    } label: {
                                        Image(.plus)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .padding(12)
                                            .background(
                                                Circle()
                                                    .fill(.white100)
                                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                            )
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(width: 214, height: 267)
                            .padding(.bottom, 20)
                        } else {
                            // 사진 선택 플레이스홀더 (CarabinerAddKeyringButton 스타일)
                            Button {
                                showPhotoPicker = true
                            } label: {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.white100)
                                        .frame(width: 214, height: 267)
                                        .padding(.bottom, 20)

                                    // + 버튼 아이콘
                                    Image(.plus)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(.white100)
                                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                        )
                                }
                            }
                        }

                        // 2. 프레임 이미지 (중간)
                        if let frame = viewModel.selectedFrame {
                            LazyImage(url: URL(string: frame.frameURL)) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 324)
                                } else if state.isLoading {
                                    ProgressView()
                                        .frame(width: 300, height: 320)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray100)
                                        .frame(width: 300, height: 300)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                    }
                    .offset(x: 3)
                }

                // frameChain 이미지 (위에 겹침)
                Image("frameChain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 170)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.selectedPhotoImage = uiImage
                    // 새 사진 선택 시 변환 초기화
                    viewModel.photoScale = 1.0
                    viewModel.photoRotation = .zero
                    viewModel.photoOffset = .zero
                    currentScale = 1.0
                    currentRotation = .zero
                    currentOffset = .zero
                    showEditButton = false
                }
            }
        }
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
        }
    }

    // MARK: - Photo Gestures

    /// 사진 편집 제스처 (확대/축소, 회전, 이동)
    private var photoGestures: some Gesture {
        // 확대/축소 제스처 (최소 0.5배, 최대 3.0배)
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                currentScale = value
            }
            .onEnded { value in
                let newScale = viewModel.photoScale * value
                // 범위 제한: 0.5 ~ 3.0
                viewModel.photoScale = min(max(newScale, 0.5), 3.0)
                currentScale = 1.0
            }

        // 회전 제스처
        let rotationGesture = RotationGesture()
            .onChanged { value in
                currentRotation = value
            }
            .onEnded { value in
                viewModel.photoRotation += value
                currentRotation = .zero
            }

        // 이동 제스처
        let dragGesture = DragGesture()
            .onChanged { value in
                currentOffset = CGSize(
                    width: value.translation.width,
                    height: value.translation.height
                )
            }
            .onEnded { value in
                viewModel.photoOffset = CGSize(
                    width: viewModel.photoOffset.width + value.translation.width,
                    height: viewModel.photoOffset.height + value.translation.height
                )
                currentOffset = .zero
            }

        // 모든 제스처를 동시에 적용
        return magnificationGesture
            .simultaneously(with: rotationGesture)
            .simultaneously(with: dragGesture)
    }

    /// 최종 적용될 scale (기존 scale + 현재 제스처 scale, 범위 제한 0.5 ~ 3.0)
    private var finalScale: CGFloat {
        let calculatedScale = viewModel.photoScale * currentScale
        return min(max(calculatedScale, 0.5), 3.0)
    }

    /// 최종 적용될 rotation (기존 rotation + 현재 제스처 rotation)
    private var finalRotation: Angle {
        viewModel.photoRotation + currentRotation
    }

    /// 최종 적용될 offset (기존 offset + 현재 제스처 offset)
    private var finalOffset: CGSize {
        CGSize(
            width: viewModel.photoOffset.width + currentOffset.width,
            height: viewModel.photoOffset.height + currentOffset.height
        )
    }
}
