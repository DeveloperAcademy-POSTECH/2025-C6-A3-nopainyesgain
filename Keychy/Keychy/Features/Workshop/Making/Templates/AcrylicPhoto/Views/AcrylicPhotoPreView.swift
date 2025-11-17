//
//  MakingStep1.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import PhotosUI

struct AcrylicPhotoPreView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @State var viewModel: AcrylicPhotoVM
    @Environment(UserManager.self) private var userManager
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showGuide = false
    @State private var hasAppearedBefore = false
    @State private var capturedImage: UIImage?

    var body: some View {
        TemplatePreviewBody(
            template: viewModel.template,
            fetchTemplate: { await viewModel.fetchTemplate() },
            onMake: {
                showGuide = true
                selectedItem = nil
            },
            router: router
        )
        .onChange(of: selectedItem) { _, selectedImage in
            if let selectedImage {
                viewModel.loadImage(from: selectedImage)

                // 시트가 닫히고 나서 화면 전환
                showPhotoPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    router.push(.acrylicPhotoCrop)
                }
            }
        }
        .onAppear { // 처음이 아니고 뒤로 왔을 때만 PhotosPicker 자동으로 띄우기
            if hasAppearedBefore {
                viewModel.resetImageData()
                selectedItem = nil
                capturedImage = nil

                // 포토피커 자동 열기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPhotoPicker = true
                }
            }
            hasAppearedBefore = true
        }
        .sheet(isPresented: $showGuide) {
            if let template = viewModel.template {
                AcrylicPhotoGuiding(
                    showPhotoPicker: $showPhotoPicker,
                    showCamera: $showCamera,
                    guidingText: template.guidingText,
                    guidingImageURL: template.guidingImageURL
                )
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images
        )
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage, isPresented: $showCamera)
                .background(Color.black)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newImage in
            if let newImage {
                // 카메라로 찍은 이미지를 ViewModel에 직접 할당
                viewModel.selectedImage = newImage

                // Crop 화면으로 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.resetToCenter()
                    router.push(.acrylicPhotoCrop)
                }
            }
        }
    }
}
