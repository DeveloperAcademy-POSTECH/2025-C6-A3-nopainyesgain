//
//  FestivalView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI
import _LocationEssentials
import CoreLocation

struct FestivalView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>
    @State private var viewModel = FestivalViewModel()
    @State private var locationManager = LocationManager()

    @State private var currentPage = 0

    // ⭐️ 집에서 테스트 하실 땐 여기에 나와있는 longtitude, latitude를 수정하시면 됩니다!(경도, 위도)
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
                latitude: 36.076790,
                longitude: 129.569939,
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
                latitude: 36.014342,
                longitude: 129.325749,
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
                    Text(currentLocationAddress)
                        .typography(.suit15B)
                        .foregroundStyle(.gray500)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
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
    
    // MARK: - Helpers
    
    private var currentLocationAddress: String {
        if let address = locationManager.currentAddress {
            return address
        } else if locationManager.currentLocation != nil {
            return "주소를 가져오는 중..."
        } else {
            return "위치 정보를 가져오는 중..."
        }
    }
    
    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "미설정"
        case .restricted: return "제한됨"
        case .denied: return "거부됨 ⚠️"
        case .authorizedAlways: return "항상 허용 ✅"
        case .authorizedWhenInUse: return "사용 중 허용 ✅"
        @unknown default: return "알 수 없음"
        }
    }
}
