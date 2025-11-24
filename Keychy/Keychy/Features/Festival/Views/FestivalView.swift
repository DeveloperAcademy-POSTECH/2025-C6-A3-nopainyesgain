//
//  FestivalView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>
    @State private var viewModel = FestivalViewModel()

    @State private var currentPage = 0

    // 목데이터
    let festivals = [
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "homigot",
            isLocked: true
        ),
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "showcase25",
            isLocked: true
        ),
        (
            title: "페스티벌 이름",
            location: "경북 포항시 남구 지곡로 80 C5",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "youngonedae",
            isLocked: true
        ),
    ]

    var body: some View {
        // 카드 스와이프 뷰 (중앙 배치)
        VStack(alignment: .leading, spacing: 50) {
            VStack(alignment: .leading, spacing: 10) {
                Text("페스티벌")
                    .typography(.nanum32EB)
                    .foregroundStyle(.black100)
                HStack(spacing: 3) {
                    Image(.mapPinIcon)
                    Text("경북 포항시 남구 지곡로 80 C5")
                        .typography(.suit15B)
                        .foregroundStyle(.gray500)
                        .onTapGesture(count: 5) {
                            router.push(.showcase25BoardView)
                        }
                }
            }
            .padding(18)
            
            cardPagerView(
                pageCount: festivals.count,
                currentPage: $currentPage
            ) { index in
                festivalCard(
                    title: festivals[index].title,
                    location: festivals[index].location,
                    startDate: festivals[index].startDate,
                    endDate: festivals[index].endDate,
                    distance: festivals[index].distance,
                    imageName: festivals[index].imageName,
                    isLocked: festivals[index].isLocked,
                    enterAction: { router.push(.showcase25BoardView) }
                )
            }

            // uploadButton
        }
        .background {
            Image(.festivalBG)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
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
