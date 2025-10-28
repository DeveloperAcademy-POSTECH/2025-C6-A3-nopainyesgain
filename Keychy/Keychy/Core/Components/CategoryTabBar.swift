//
//  CategoryTabBar.swift
//  Keychy
//
//  Created by rundo on 10/28/25.
//

import SwiftUI

/// 가로 스크롤 카테고리 탭바
///
/// 카테고리를 선택할 수 있는 가로 스크롤 탭바입니다.
/// 선택된 카테고리는 보라색 강조와 밑줄로 표시됩니다.
///
/// **사용 예시:**
/// ```swift
/// @State private var selectedCategory = "키링"
/// let categories = ["KEYCHY!", "키링", "카라비너", "이펫트", "배경"]
///
/// CategoryTabBar(
///     categories: categories,
///     selectedCategory: $selectedCategory
/// )
/// ```
struct CategoryTabBar: View {
    /// 표시할 카테고리 목록
    let categories: [String]
    
    /// 현재 선택된 카테고리
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(categories, id: \.self) { category in
                    CategoryTabButton(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Category Tab Button

/// 카테고리 탭 버튼
///
/// 선택 상태에 따라 스타일이 변경되는 버튼입니다.
/// - 선택됨: 굵은 폰트 + 보라색 + 밑줄
/// - 미선택: 일반 폰트 + 검정색 + 밑줄 없음
private struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .typography(isSelected ? .suit15B25 : .suit15SB25)
                    .foregroundStyle(isSelected ? Color.main500 : Color.black100)
                
                Rectangle()
                    .fill(isSelected ? Color.main500 : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

// MARK: - Preview

#Preview("예시 프리뷰") {
    @Previewable @State var selectedCategory = "키링"
    let categories = ["KEYCHY!", "키링", "카라비너", "이펫트", "배경"]
    
    VStack() {
        CategoryTabBar(
            categories: categories,
            selectedCategory: $selectedCategory
        )
        
        Spacer()
    }
    .padding()
}
