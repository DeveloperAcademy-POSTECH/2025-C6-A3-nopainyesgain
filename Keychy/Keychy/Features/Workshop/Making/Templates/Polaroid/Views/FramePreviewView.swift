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
        ZStack {
            // 프레임 미리보기
            VStack(spacing: 0) {
                // frameChain 이미지 (상단)
                Image("frameChain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80)
                    .offset(y: 30)
                
                // 프레임 + 사진 영역
                ZStack {
                    // 1. 선택된 사진 (맨 아래)
                    if let photoImage = viewModel.selectedPhotoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // 사진 선택 플레이스홀더
                        Button {
                            showPhotoPicker = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white100)
                                    .frame(width: 280, height: 280)
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(.gray300)
                                    
                                    Text("사진을 선택해주세요")
                                        .typography(.suit14M)
                                        .foregroundStyle(.gray400)
                                }
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
                                    .frame(width: 300, height: 300)
                            } else if state.isLoading {
                                ProgressView()
                                    .frame(width: 300, height: 300)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray100)
                                    .frame(width: 300, height: 300)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
        }
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
        .task {
            // 뷰 계층이 완전히 준비될 때까지 약간 대기
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            // 씬이 준비되었음을 알림
            onSceneReady()
        }
    }
}
