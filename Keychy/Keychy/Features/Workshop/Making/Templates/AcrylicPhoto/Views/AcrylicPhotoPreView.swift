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
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showGuide = false
    @State private var hasAppearedBefore = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                keyringPreivew
                Spacer()
                keyringInfo(template: viewModel.template)
            }
            .padding(.bottom, 120)

            makeBtn
        }
        .padding(.horizontal, 35)
        .toolbar(.hidden, for: .tabBar)
        .task {
            // 템플릿 데이터 가져오기
            await viewModel.fetchTemplate()
        }
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
                showPhotoPicker = true
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
    }
}

// MARK: - KeyringScene Section
extension AcrylicPhotoPreView {
    private var keyringPreivew: some View {
        PreviewImage(
            previewURL: viewModel.template?.previewURL ?? "")
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Info Section
extension AcrylicPhotoPreView {
    @ViewBuilder
    private func keyringInfo(template: KeyringTemplate?) -> some View {
        if let template {
            PreviewInfoSection(template: template)
        } else {
            Text("템플릿 정보 없음")
        }
    }
}

extension AcrylicPhotoPreView {
    private var makeBtn: some View {
        PreviewMakingBtn(title: "만들기") {
            showGuide = true
            selectedItem = nil
        }
    }
}

#Preview {
    AcrylicPhotoPreView(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: AcrylicPhotoVM()
    )
}
