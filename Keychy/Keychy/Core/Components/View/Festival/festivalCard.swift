//
//  festivalCard.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI
import NukeUI
import CoreLocation

struct festivalCard: View {
    let title: String
    let location: String
    let startDate: String
    let endDate: String
    let distance: String
    let imageName: String
    let targetLocation: TargetLocation // 위치 기반 체크용
    let isAvailable: Bool  // 입장 가능 여부 (목데이터 구분용)
    let enterAction: () -> Void
    
    @State private var locationManager = LocationManager()
    
    var remainingDays: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        guard let endDate = formatter.date(from: endDate) else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: endDate)
        
        let components = Calendar.current.dateComponents([.day], from: today, to: end)
        return components.day ?? 0
    }
    
    // 위치 기반으로 키링 추가 가능 여부 결정 (버튼 활성화와는 별개)
    var isInRange: Bool {
        locationManager.isLocationActive(targetLocation)
    }
    
    // 현재 거리 계산
    var currentDistance: Double? {
        guard let currentLocation = locationManager.currentLocation else { return nil }
        return currentLocation.distance(from: targetLocation.coordinate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 이미지
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: screenWidth * 0.75 - 20)
                .clipped()
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading) {
                        Text("\(startDate)~\(endDate)")
                            .typography(.suit14SB)
                            .foregroundStyle(.white100)
                            .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                            .background(
                                RoundedRectangle(cornerRadius: 34)
                                    .fill(.black50)
                            )
                        if remainingDays >= 0 {
                            Text(remainingDays == 0 ? "D-day" : "D-\(remainingDays)일")
                                .typography(.suit13SB)
                                .foregroundStyle(.main500)
                                .padding(EdgeInsets(top: 2.5, leading: 8, bottom: 2.5, trailing: 8))
                                .background(
                                    RoundedRectangle(cornerRadius: 34)
                                        .fill(.main50)
                                )
                        } else {
                            Text("종료된 페스티벌")
                                .typography(.suit13SB)
                                .foregroundStyle(.white100)
                                .padding(EdgeInsets(top: 2.5, leading: 8, bottom: 2.5, trailing: 8))
                                .background(
                                    RoundedRectangle(cornerRadius: 34)
                                        .fill(.gray500)
                                )
                        }
                    }
                    .padding(10)
                }
            
            Spacer().frame(height: 15)
            
            // 페스티벌 정보
            HStack {
                Text(title)
                    .typography(.suit24B)
                    .foregroundStyle(.black100)
                Spacer()
            }
            .padding(.horizontal, 8)
            HStack {
                Text(location)
                    .typography(.suit14M)
                Spacer()
            }
            .padding(.horizontal, 8)
            
            
            Spacer().frame(height: 28)
            
            // 거리 정보 표시 (동적으로 업데이트) - 참고용으로만 표시
            if let distance = currentDistance {
                Text("내 위치로부터 \(formatDistance(distance))")
                    .typography(.suit14SB)
                    .foregroundStyle(isInRange ? .green : .gray300)
            } else {
                Text("위치 정보를 가져오는 중...")
                    .typography(.suit14SB)
                    .foregroundStyle(.gray300)
            }
            
            Spacer().frame(height: 3)
            
            // 입장 버튼 - isAvailable에 따라 활성화/비활성화
            Button {
                if isAvailable {
                    enterAction()
                }
            } label: {
                Text(isAvailable ? "입장하기" : "Coming Soon")
                    .typography(isAvailable ? .suit17B : .suit17M)
                    .foregroundStyle(isAvailable ? .white100 : .gray300)
                    .padding(.vertical, 13.5)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(isAvailable ? .main500 : .gray50)
                    )
            }
            .disabled(!isAvailable)
            .animation(.easeInOut, value: isAvailable)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 29)
                .fill(.white100)
                .frame(width: screenWidth * 0.75)
                .shadow(color: .black15, radius: 4)
        )
        .onAppear {
            // 위치 권한 요청 및 타겟 위치 설정
            locationManager.requestPermission()
            locationManager.targetLocations = [targetLocation]
        }
    }
    
    // 거리를 읽기 쉬운 형식으로 변환
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}
