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
        // 카드 스와이프 뷰 (중앙 배치)
        VStack {
            Text("페스티벌")
                .typography(.nanum32EB)
                .foregroundStyle(.black100)
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
            
            uploadButton
        }
        .task {
            if !hasInitialized {
                viewModel = FestivalViewModel(userManager: userManager)
                hasInitialized = true
            }
        }
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
