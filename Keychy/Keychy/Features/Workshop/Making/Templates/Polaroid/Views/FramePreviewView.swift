//
//  FramePreviewView.swift
//  Keychy
//
//  폴라로이드 템플릿 프레임 미리보기 뷰 (중앙 씬 영역)
//

import SwiftUI
import PhotosUI
import NukeUI
import Nuke

struct FramePreviewView: View {
    @Bindable var viewModel: PolaroidVM
    let onSceneReady: () -> Void

    @State private var showPhotoSelectSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showEditButton = false

    // 시트에서 선택한 액션을 저장
    @State private var pendingAction: PhotoAction? = nil

    enum PhotoAction {
        case camera
        case photoLibrary
    }

    // 제스처 임시 값 (제스처 중에만 사용)
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var currentOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .top) {
                    // 프레임 + 사진 영역 (VM+Frame 로직과 동일)
                    VStack {
                        Spacer()
                            .frame(height: 125)

                        // VM+Frame의 합성 로직과 동일한 배치
                        compositionView
                    }

                    // frameChain 이미지 (위에 겹침)
                    Image("frameChain")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 170)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                viewModel.selectedPhotoImage = image
                // 새 사진 선택 시 변환 초기화
                viewModel.photoScale = 1.0
                viewModel.photoRotation = .zero
                viewModel.photoOffset = .zero
                currentScale = 1.0
                currentRotation = .zero
                currentOffset = .zero
                showEditButton = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoSelectSheet, onDismiss: {
            // 시트가 완전히 닫힌 후 액션 실행
            if let action = pendingAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    switch action {
                    case .camera:
                        showCamera = true
                    case .photoLibrary:
                        showPhotoPicker = true
                    }
                    pendingAction = nil
                }
            }
        }) {
            PhotoSelectSheet(
                onCameraSelected: {
                    pendingAction = .camera
                },
                onPhotoLibrarySelected: {
                    pendingAction = .photoLibrary
                }
            )
        }
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
        let magnificationGesture = MagnificationGesture(minimumScaleDelta: 0.0)
            .onChanged { value in
                Task { @MainActor in
                    currentScale = value
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    let newScale = viewModel.photoScale * value
                    // 범위 제한: 0.5 ~ 3.0
                    viewModel.photoScale = min(max(newScale, 0.5), 3.0)
                    currentScale = 1.0
                }
            }

        // 회전 제스처
        let rotationGesture = RotationGesture(minimumAngleDelta: .zero)
            .onChanged { value in
                Task { @MainActor in
                    currentRotation = value
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    viewModel.photoRotation += value
                    currentRotation = .zero
                }
            }

        // 이동 제스처 (최소 거리 10 설정으로 탭과 구분)
        let dragGesture = DragGesture(minimumDistance: 10)
            .onChanged { value in
                Task { @MainActor in
                    currentOffset = CGSize(
                        width: value.translation.width,
                        height: value.translation.height
                    )
                }
            }
            .onEnded { value in
                Task { @MainActor in
                    viewModel.photoOffset = CGSize(
                        width: viewModel.photoOffset.width + value.translation.width,
                        height: viewModel.photoOffset.height + value.translation.height
                    )
                    currentOffset = .zero
                }
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

    // MARK: - Composition View (VM+Frame 로직과 동일)

    /// VM+Frame의 합성 로직과 정확히 동일한 배치
    @ViewBuilder
    private var compositionView: some View {
        // VM+Frame과 동일한 상수 값
        let targetFrameHeight: CGFloat = 324
        let photoWidth: CGFloat = 214
        let photoHeight: CGFloat = 267
        let photoBottomPadding: CGFloat = 20
        let photoOffsetX: CGFloat = 3

        ZStack(alignment: .topLeading) {
            if let frame = viewModel.selectedFrame {
                // 프레임 크기 계산
                LazyImage(url: URL(string: frame.frameURL)) { state in
                    if state.isLoading {
                        LoadingAlert(type: .short, message: nil)
                            .frame(height: targetFrameHeight)
                    } else if let image = state.image {
                        let frameAspect = (state.imageContainer?.image.size.width ?? 1) / (state.imageContainer?.image.size.height ?? 1)
                        let targetFrameWidth = targetFrameHeight * frameAspect

                        // 사진 위치 계산 (VM+Frame과 동일)
                        let photoX = (targetFrameWidth - photoWidth) / 2 + photoOffsetX
                        let photoY = targetFrameHeight - photoHeight - photoBottomPadding

                        ZStack(alignment: .topLeading) {
                            // 1. 사진 (맨 아래)
                            if let photoImage = viewModel.selectedPhotoImage {
                                ZStack {
                                    Image(uiImage: photoImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: photoWidth, height: photoHeight)
                                        .scaleEffect(finalScale)
                                        .rotationEffect(finalRotation)
                                        .offset(finalOffset)
                                        .clipped()
                                        .contentShape(Rectangle())
                                        .gesture(photoGestures)
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showEditButton.toggle()
                                            }
                                        }

                                    // 편집 버튼
                                    if showEditButton {
                                        Button {
                                            showPhotoSelectSheet = true
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
                                                .offset(y: -20)
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .position(x: photoX + photoWidth / 2, y: photoY + photoHeight / 2)
                            } else {
                                // 사진 선택 플레이스홀더
                                Button {
                                    showPhotoSelectSheet = true
                                } label: {
                                    ZStack {
                                        SimpleAnimatedImage(url: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FPolaroid%2FframPlaceHolder.png?alt=media&token=3d8ac227-7d96-4355-9e1d-21dfab19c5d5")
                                            .frame(width: photoWidth, height: photoHeight)
                                            .padding(.bottom, 20)


                                        Image(.plus)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22 )
                                            .padding(10)
                                            .background(
                                                Circle()
                                                    .fill(.white100)
                                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                            )
                                            .offset(y: -20)
                                    }
                                }
                                .position(x: photoX + photoWidth / 2, y: photoY + photoHeight / 2)
                                .offset(x: -3)
                            }

                            // 2. 프레임 이미지 (위에 오버레이)
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: targetFrameHeight)
                                .allowsHitTesting(false)
                        }
                        .frame(width: targetFrameWidth, height: targetFrameHeight)
                    } else if state.isLoading {
                        ProgressView()
                            .frame(height: targetFrameHeight)
                    } else {
                        Rectangle()
                            .fill(Color.gray100)
                            .frame(height: targetFrameHeight)
                    }
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        picker.cameraViewTransform = .identity
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
