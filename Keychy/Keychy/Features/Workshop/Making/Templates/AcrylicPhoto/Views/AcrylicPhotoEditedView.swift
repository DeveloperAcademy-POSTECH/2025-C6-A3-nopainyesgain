//
//  MakingStep2.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct AcrylicPhotoEditedView: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: AcrylicPhotoVM

    var body: some View {
        ZStack {
            VStack {
                let image = viewModel.removedBackgroundImage

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                
                Button {
                    viewModel.isProcessing = true
                    
                    AcrylicPhotoVM.removeBackgroundAndCrop(from: image) { croppedImage in
                        viewModel.isProcessing = false
                        
                        if let croppedImage = croppedImage {
                            viewModel.bodyImage = croppedImage
                            router.push(.acrylicPhotoCustomizing)
                        } else {
                            viewModel.errorMessage = "이미지 처리에 실패했습니다."
                        }
                    }
                } label: {
                    Text("편집하러 가기")
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 50)
                }
                .disabled(viewModel.isProcessing)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if viewModel.isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("이미지 처리 중...")
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
        .navigationTitle("편집 완료!")
    }
}
