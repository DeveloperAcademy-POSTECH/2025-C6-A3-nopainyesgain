//
//  festivalCard.swift
//  Keychy
//
//  Created by seo on 11/23/25.
//

import SwiftUI
import NukeUI

struct festivalCard: View {
    let title: String
    let location: String
    let startDate: String
    let endDate: String
    let distance: String
    let imageName: String
    let isLocked: Bool
    let enterAction: () -> Void
    
    var remainingDays: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        guard let endDate = formatter.date(from: endDate) else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: endDate)
        
        let components = Calendar.current.dateComponents([.day], from: today, to: end)
        return components.day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 이미지
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth * 0.75 - 20)
                    .clipped()
                    .overlay(alignment: .top) {
                        HStack {
                            Text("\(startDate)~\(endDate)")
                                .typography(.suit14SB)
                                .foregroundStyle(.white100)
                                .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                .background(
                                    RoundedRectangle(cornerRadius: 34)
                                        .fill(.black50)
                                )
                            Spacer()
                            Text("남은 기간 \(remainingDays)일")
                                .typography(.suit13SB)
                                .foregroundStyle(.main500)
                                .padding(EdgeInsets(top: 2.5, leading: 8, bottom: 2.5, trailing: 8))
                                .background(
                                    RoundedRectangle(cornerRadius: 34)
                                        .fill(.main50)
                                )
                        }
                        .padding(10)
                    }
//                LazyImage(url: URL(string: imageName)) { state in
//                    if let image = state.image {
//                        image
//                            .resizable()
//                            .scaledToFit()
//                    } else {
//                        LoadingAlert(type: .short, message: "")
//                    }
//                }
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
            
            Text("내 위치로부터 1.5km")
                .typography(.suit14SB)
                .foregroundStyle(.main500)
                .opacity(isLocked ? 1 : 0)
            
            Spacer().frame(height: 3)
            
            Button {
                // 임시로 버튼 비활성화 해둡니다...^^
            } label: {
                Text("입장하기")
                    .typography(isLocked ? .suit17M : .suit17B)
                    .foregroundStyle(isLocked ? .gray300 : .white100)
                    .padding(.vertical, 13.5)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 34)
                            .fill(isLocked ? .gray50 : .main500)
                    )
            }
            .disabled(isLocked)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 29)
                .fill(.white100)
                .frame(width: screenWidth * 0.75)
                .shadow(color: .black15, radius: 4)
        )
    }
}
