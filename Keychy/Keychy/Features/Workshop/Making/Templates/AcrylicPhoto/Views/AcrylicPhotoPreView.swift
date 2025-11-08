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

    /// 템플릿 보유 여부 확인
    private var isOwned: Bool {
        guard let user = userManager.currentUser,
              let templateId = viewModel.template?.id else { return false }
        return user.templates.contains(templateId)
    }

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
                capturedImage = nil
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

// MARK: - KeyringScene Section
extension AcrylicPhotoPreView {
    private var keyringPreivew: some View {
        ItemDetailImage(
            itemURL: viewModel.template?.previewURL ?? "")
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Info Section
extension AcrylicPhotoPreView {
    @ViewBuilder
    private func keyringInfo(template: KeyringTemplate?) -> some View {
        if let template {
            ItemDetailInfoSection(item: template)
        } else {
            Text("템플릿 정보 없음")
        }
    }
}

extension AcrylicPhotoPreView {
    private var makeBtn: some View {
        Group {
            if let template = viewModel.template {
                KeyringTemplateActionButton(
                    template: template,
                    isOwned: isOwned,
                    onMake: {
                        showGuide = true
                        selectedItem = nil
                    },
                    onPurchase: {
                        // TODO: 구매 로직 구현
                        print("구매: \(template.name) - \(template.workshopPrice) 코인")
                    }
                )
            } else {
                // 템플릿 로딩 중
                ProgressView()
            }
        }
    }
}

#Preview {
    AcrylicPhotoPreView(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: AcrylicPhotoVM()
    )
}
