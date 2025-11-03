//
//  CategoryTabBarWithLongPress.swift
//  Keychy
//
//  Created by Jini on 11/3/25.
//

import SwiftUI

// 기존 CategoryTabBar를 재사용하되, long press 기능만 추가
struct CategoryTabBarWithLongPress: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let onLongPress: (String, CGRect) -> Void  // 카테고리와 위치 전달
    let editableCategories: Set<String>  // 편집 가능한 카테고리들
    
    @State private var buttonFrames: [String: CGRect] = [:]
    @State private var pressStates: [String: PressState] = [:]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(categories, id: \.self) { category in
                    CategoryTabButtonWithLongPress(
                        title: category,
                        isSelected: selectedCategory == category,
                        isEditable: editableCategories.contains(category),
                        onTap: {
                            selectedCategory = category
                        },
                        onLongPress: { frame in
                            onLongPress(category, frame)
                        }
                    )
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Long Press 있는 CategoryTabBar 버튼
private struct CategoryTabButtonWithLongPress: View {
    let title: String
    let isSelected: Bool
    let isEditable: Bool
    let onTap: () -> Void
    let onLongPress: (CGRect) -> Void
    
    @State private var buttonFrame: CGRect = .zero
    @State private var pressStartTime: Date?
    @State private var timer: Timer?
    
    var body: some View {
        // 기존 CategoryTabBar 스타일
        VStack(spacing: Spacing.sm) {
            Text(title)
                .typography(isSelected ? .suit15B25 : .suit15SB25)
                .foregroundStyle(isSelected ? Color.main500 : Color.black100)
            
            Rectangle()
                .fill(isSelected ? Color.main500 : Color.clear)
                .frame(height: 2)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: ButtonFramePreferenceKey.self,
                        value: geometry.frame(in: .global)
                    )
            }
        )
        .onPreferenceChange(ButtonFramePreferenceKey.self) { frame in
            buttonFrame = frame
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if pressStartTime == nil {
                onTap()
            }
        }
        .gesture( // Long press 제스쳐 직접 구현
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if pressStartTime == nil {
                        pressStartTime = Date()
                        
                        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            if isEditable {
                                onLongPress(buttonFrame)
                            }
                            pressStartTime = nil
                        }
                    }
                    
                    if abs(value.translation.width) > 10 || abs(value.translation.height) > 10 {
                        timer?.invalidate()
                        pressStartTime = nil
                    }
                }
                .onEnded { _ in
                    if let startTime = pressStartTime {
                        let duration = Date().timeIntervalSince(startTime)
                        if duration < 0.3 {
                            onTap()
                        }
                    }
                    
                    timer?.invalidate()
                    pressStartTime = nil
                }
        )
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

// MARK: - 상태관리용
private struct PressState {
    var startTime: Date?
    var timer: Timer?
}

private struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
