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
    @State private var hasAppearedBefore = false

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            keyringScene
            keyringInfo
            Spacer()
            makeBtn
        }
        .padding(.horizontal, 20)
        .toolbar(.hidden, for: .tabBar)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images
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
        .onAppear {
            // 처음이 아니고 뒤로 왔을 때만 PhotosPicker 자동으로 띄우기
            if hasAppearedBefore {
                viewModel.resetImageData()
                selectedItem = nil
                showPhotoPicker = true
            }
            hasAppearedBefore = true
        }
    }
}

// MARK: - KeyringScene Section
extension AcrylicPhotoPreView {
    private var keyringScene: some View {
        Image("ddochi")
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Info Section
extension AcrylicPhotoPreView {
    private var keyringInfo: some View {
        VStack(alignment: .leading) {
            keyringFilterTag
                .padding(.bottom, 10)
            keyringDescription
        }
    }
    
    // TODO: - 유료키링 표시 -> 로직 필요
    private var keyringPrice: some View {
        Text("")
    }
    
    // TODO: - 키링 분류 태그 -> 로직 필요
    private var keyringFilterTag: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(Color(#colorLiteral(red: 0.9096680284, green: 0.9096679091, blue: 0.9096680284, alpha: 1)))
                .frame(width: 65, height: 23)
            
            Text("#이미지형")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(#colorLiteral(red: 0.4626464844, green: 0.4626464844, blue: 0.4626464844, alpha: 1)))
                .multilineTextAlignment(.center)
        }
    }
    
    // TODO: - 키링 설명 태그 -> 로직 필요
    private var keyringDescription: some View {
        VStack(alignment: .leading) {
            Text("기본 아크릴 키링")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.bottom, 1)
            Text("어떤 키링인지에 대한 설명")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(#colorLiteral(red: 0.4626464844, green: 0.4626464844, blue: 0.4626464844, alpha: 1)))
        }
    }
}


// TODO: - 컴포넌트화 필요
// Next Step Btn
extension AcrylicPhotoPreView {
    private var makeBtn: some View {
        Button {
            showPhotoPicker = true
            selectedItem = nil
        } label: {
            Text("만들기")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(Color(#colorLiteral(red: 0.9998622537, green: 0.1881143153, blue: 0.3372095823, alpha: 1)))

    }
}

#Preview {
    AcrylicPhotoPreView(
        router: NavigationRouter<WorkshopRoute>(),
        viewModel: AcrylicPhotoVM()
    )
}
