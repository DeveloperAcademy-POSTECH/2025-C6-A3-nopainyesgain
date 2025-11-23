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
    
    @State private var currentPage = 0
    
    init(router: NavigationRouter<FestivalRoute>) {
        self.router = router
        _viewModel = State(initialValue: FestivalViewModel(userManager: UserManager.shared))
    }
    // 목데이터
    let festivals = [
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            dateRange: "2025.11.01 ~ 2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "homigotFestival",
            isLocked: true
        ),
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            dateRange: "2025.11.28 ~ 2025.11.28",
            distance: "내 위치로 부터 1.5km",
            imageName: "showcaseFestival",
            isLocked: false
        ),
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            dateRange: "2025.11.01 ~ 2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "youngildaeFestival",
            isLocked: true
        ),
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // 카드 스와이프 뷰 (중앙 배치)
            VStack {
                Spacer()
                
                cardPagerView(
                    pageCount: festivals.count,
                    currentPage: $currentPage
                ) { index in
                    festivalCard(
                        title: festivals[index].title,
                        location: festivals[index].location,
                        dateRange: festivals[index].dateRange,
                        distance: festivals[index].distance,
                        imageName: festivals[index].imageName,
                        isLocked: festivals[index].isLocked,
                        enterAction: { router.push(.showcase25Board) }
                    )
                }
                
                Spacer()
            }
            
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
