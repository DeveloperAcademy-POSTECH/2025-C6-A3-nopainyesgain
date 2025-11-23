//
//  FestivalView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>
    @Environment(UserManager.self) private var userManager
    @State private var viewModel: FestivalViewModel
    @State private var hasInitialized = false

    init(router: NavigationRouter<FestivalRoute>) {
        self.router = router
        _viewModel = State(initialValue: FestivalViewModel(userManager: UserManager.shared))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 배경 이미지
            Image(.festivalTrailer)
                .resizable()
                .scaledToFill()
                .offset(y: getBottomPadding(34) == 34 ? 50 : 0)
                .frame(width: screenWidth, height: screenHeight)

            // 네비게이션 바
            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task {
            if !hasInitialized {
                viewModel = FestivalViewModel(userManager: userManager)
                hasInitialized = true
            }
        }
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        ZStack(alignment: .topTrailing) {
            CustomNavigationBar {
                Spacer()
                    .frame(width: 44, height: 44)
                
            } center: {
                Text("페스티벌")
                    .typography(.notosans17M)
            } trailing: {
                Spacer()
                    .frame(width: 44, height: 44)
            }
            
            HStack {
                // 업로드 버튼 (왼쪽 상단)
                uploadButton
                    .padding(.trailing, 16)
                    .padding(.top, getSafeAreaTop())
                
                Spacer()
                
                // 쇼케이스 입장 버튼
                showcase25Btn
                    .padding(.trailing, 16)
                    .padding(.top, getSafeAreaTop())
            }
        }
    }
    
    // 쇼케이스 입장 버튼
    private var showcase25Btn: some View {
        Button {
            router.push(.showcase25Board)
        } label: {
            HStack(spacing: 0) {
                Image(.deleteAlert)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36)
                
                Text("입장하기")
                    .typography(.nanum16EB)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(height: 44)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    // MARK: - Upload Button

    private var uploadButton: some View {
        Button {
            Task {
                await viewModel.uploadSampleData()
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
        }
        .disabled(viewModel.isUploading)
        .opacity(viewModel.isUploading ? 0.5 : 1.0)
    }
}

// MARK: - Helper

private func getSafeAreaTop() -> CGFloat {
    guard let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?.windows
        .first(where: { $0.isKeyWindow }) else {
        return 0
    }
    return window.safeAreaInsets.top
}
