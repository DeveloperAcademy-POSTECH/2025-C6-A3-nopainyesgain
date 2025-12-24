//
//  WidgetOnboardingStepView.swift
//  Keychy
//
//  Created by Jini on 11/16/25.
//

import SwiftUI

struct WidgetOnboardingStepView: View {
    let step: WidgetOnboardingStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // 이미지
            Image(step.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
            
            // 단계 번호와 설명
            HStack(spacing: 16) {
                // 단계 번호
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.main100)
                        .frame(width: 32, height: 32)
                    
                    Text("\(step.id)")
                        .typography(.malang24B)
                        .foregroundColor(.main500)
                        .offset(y: -1)
                }
                .padding(.vertical, 10)
                
                // 단계 설명
                Text(step.highlightedTitle)
                    .typography(.suit16SB)
                    .foregroundColor(.black)
                
            }
            .padding(.horizontal, 25)

        }
    }
}

struct WidgetOnboardingStep: Identifiable {
    let id: Int
    let title: String
    let imageName: String
    let highlightKeywords: [HighlightKeyword]?
    
    var highlightedTitle: AttributedString {
        var attributed = AttributedString(title)
        
        guard let keywords = highlightKeywords else {
            return attributed
        }
        
        // 각 키워드를 지정된 스타일로 강조
        for keyword in keywords {
            if let range = attributed.range(of: keyword.text) {
                attributed[range].foregroundColor = .main500
                attributed[range].font = keyword.style.font
            }
        }
        
        return attributed
    }
}

// 가이딩 내용
extension WidgetOnboardingStep {
    static let steps: [WidgetOnboardingStep] = [
        WidgetOnboardingStep(
            id: 1,
            title: "홈 화면을 길게 눌러 왼쪽 위의\n편집 버튼을 누르고 위젯 추가를 선택해주세요.",
            imageName: "widget1",
            highlightKeywords: [
                HighlightKeyword("편집", style: .semibold),
                HighlightKeyword("위젯 추가", style: .semibold)
            ]
        ),
        WidgetOnboardingStep(
            id: 2,
            title: "위젯 목록에서 KEYCHY를 찾아 선택합니다.",
            imageName: "widget2",
            highlightKeywords: [
                HighlightKeyword("KEYCHY", style: .extrabold)
            ]
        ),
        WidgetOnboardingStep(
            id: 3,
            title: "원하는 크기의 위젯을 고르고\n위젯 추가를 눌러주세요.",
            imageName: "widget3",
            highlightKeywords: nil
        ),
        WidgetOnboardingStep(
            id: 4,
            title: "추가된 위젯을 바로 터치해\n표시할 키링을 골라주세요.",
            imageName: "widget4",
            highlightKeywords: nil
        ),
        WidgetOnboardingStep(
            id: 5,
            title: "혹은 위젯을 꾹 눌러 위젯 편집에서 표시할 키링을 바꿀 수도 있어요.",
            imageName: "widget5",
            highlightKeywords: nil
        )
    ]
}
