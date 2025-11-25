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
    @State private var locationManager = LocationManager()

    @State private var currentPage = 0

    // 목데이터
    let festivals = [
        (
            title: "호미곶 상생의 손",
            location: "경상북도 포항시 남구 호미곶면 해맞이로 136",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "homigot",
            targetLocation: TargetLocation(
                name: "C5",
                latitude: 36.014342,
                longitude: 129.325749,
                radius: 100 // 100m 반경
            )
        ),
        (
            title: "SHOWCASE25",
            location: "경북 포항시 남구 지곡로 80 C5",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "showcase25",
            targetLocation: TargetLocation(
                name: "C5",
                latitude: 36.007918,
                longitude: 129.334490,
                radius: 100
            )
        ),
        (
            title: "영일대 전망대",
            location: "경상북도 포항시 북구 삼호로",
            startDate: "2025.11.01",
            endDate: "2025.11.30",
            distance: "내 위치로 부터 1.5km",
            imageName: "youngonedae",
            targetLocation: TargetLocation(
                name: "C5",
                latitude: 36.061582,
                longitude: 129.383020,
                radius: 100
            )
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
                    targetLocation: festivals[index].targetLocation,
                    enterAction: { router.push(.showcase25BoardView) }
                )
            }

             uploadButton
        }
        .background {
            Image(.festivalBG)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .onAppear {
            // 뷰가 나타날 때 위치 권한 요청 (Info.plist 설정 필수)
            locationManager.requestPermission()
            // 페스티벌 목표 위치들 설정
            locationManager.targetLocations = festivals.map { $0.targetLocation }
        }
        .onDisappear {
            // 뷰가 사라질 때 위치 추적 중지 (배터리 절약)
            locationManager.stopTracking()
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
