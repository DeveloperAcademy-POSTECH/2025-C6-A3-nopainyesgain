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
                            Image(uiImage: photoImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 214, height: 267)
                                .clipped()  // frame 밖으로 나간 부분 잘라내기
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
                }
            }
        }
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
        }
    }
}
