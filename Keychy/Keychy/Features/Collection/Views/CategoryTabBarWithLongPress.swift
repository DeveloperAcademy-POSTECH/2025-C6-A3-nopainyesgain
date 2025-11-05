//
//  CategoryTabBarWithLongPress.swift
//  Keychy
//
//  Created by Jini on 11/3/25.
//

import SwiftUI
import UIKit

// 기존 CategoryTabBar를 재사용하되, long press 기능만 추가
struct CategoryTabBarWithLongPress: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let onLongPress: (String, CGRect) -> Void
    let editableCategories: Set<String>
    
    @State private var buttonFrames: [String: CGRect] = [:]
    @State private var isPressing: [String: Bool] = [:]
    @State private var longPressTriggered: Bool = false
    @State private var pressStartTime: Date?
    @State private var longPressTimer: Timer?
    @State private var styleTimer: Timer?
    @State private var pressedCategory: String?
    @State private var hasMoved: Bool = false
    @State private var initialLocation: CGPoint = .zero
    
    var body: some View {
        GeometryReader { scrollGeometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing:0) {
                    ForEach(categories, id: \.self) { category in
                        CategoryTabButton(
                            title: category,
                            isSelected: selectedCategory == category,
                            isPressing: isPressing[category] ?? false
                        )
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ButtonFramePreferenceKey.self,
                                        value: [category: geometry.frame(in: .global)]
                                    )
                            }
                        )
                    }
                }
            }
            .onPreferenceChange(ButtonFramePreferenceKey.self) { frames in
                buttonFrames = frames
            }
            .scrollBounceBehavior(.basedOnSize)
            // ScrollView에 제스처 적용
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value, in: scrollGeometry)
                    }
                    .onEnded { value in
                        handleDragEnded(value, in: scrollGeometry)
                    }
            )
        }
        .frame(height: 35)

    }
    
    // MARK: - Drag Changed
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        // 첫 터치
        if pressStartTime == nil {
            pressStartTime = Date()
            longPressTriggered = false
            hasMoved = false
            
            let globalLocation = CGPoint(
                x: value.startLocation.x + geometry.frame(in: .global).minX,
                y: value.startLocation.y + geometry.frame(in: .global).minY
            )
            initialLocation = globalLocation
            
            // 어떤 버튼을 눌렀는지 확인
            if let category = findTappedCategory(at: globalLocation) {
                pressedCategory = category
                
                // 편집 가능한 태그만 처리
                if editableCategories.contains(category) {
                    // 0.1초 후 스타일 변경
                    styleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        if !hasMoved && !longPressTriggered {
                            isPressing[category] = true
                        }
                    }
                    
                    // 0.3초 후 long press
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        if !hasMoved && !longPressTriggered,
                           let frame = buttonFrames[category] {
                            
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            onLongPress(category, frame)
                            longPressTriggered = true
                        }
                    }
                }
            }
        }
        
        // 드래그 거리 체크
        let horizontalDrag = abs(value.translation.width)
        
        // 5pt 이상 움직이면 스크롤
        if horizontalDrag > 5 && !hasMoved {
            hasMoved = true
            cancelPress()
        }
    }
    
    // MARK: - Drag Ended
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        defer {
            resetPress()
        }
        
        // Long press 실행됐으면 종료
        guard !longPressTriggered else { return }
        
        // 스크롤했으면 종료
        guard !hasMoved else { return }
        
        let horizontalDrag = abs(value.translation.width)
        
        // 거의 안 움직이고 빠르게 떼면 탭
        if horizontalDrag < 5, let startTime = pressStartTime {
            let duration = Date().timeIntervalSince(startTime)
            if duration < 0.3 {
                // 로컬 좌표를 글로벌 좌표로 변환
                let globalLocation = CGPoint(
                    x: value.startLocation.x + geometry.frame(in: .global).minX,
                    y: value.startLocation.y + geometry.frame(in: .global).minY
                )
                
                if let category = findTappedCategory(at: globalLocation) {
                    selectedCategory = category
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // 터치 위치에서 어떤 카테고리인지 찾기
    private func findTappedCategory(at location: CGPoint) -> String? {
        for (category, frame) in buttonFrames {
            // 약간의 여유 공간 추가 (터치 영역 확대)
            let expandedFrame = frame.insetBy(dx: -5, dy: -5)
            if expandedFrame.contains(location) {
                return category
            }
        }
        return nil
    }
    
    // Press 취소
    private func cancelPress() {
        styleTimer?.invalidate()
        styleTimer = nil
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        if let category = pressedCategory {
            isPressing[category] = false
        }
    }
    
    // 완전 초기화
    private func resetPress() {
        styleTimer?.invalidate()
        styleTimer = nil
        longPressTimer?.invalidate()
        longPressTimer = nil
        pressStartTime = nil
        
        if let category = pressedCategory {
            isPressing[category] = false
        }
        
        pressedCategory = nil
        longPressTriggered = false
        hasMoved = false
    }
}

// MARK: - Long Press 있는 CategoryTabBar 버튼
private struct CategoryTabButton: View {
    let title: String
    let isSelected: Bool
    let isPressing: Bool
    
    var body: some View {
        // 기존 CategoryTabBar 스타일
        VStack(spacing: Spacing.sm) {
            Text(title)
                .typography(
                    isPressing ? .suit15B25 :
                        isSelected ? .suit15B25 : .suit15SB25
                )
                .foregroundStyle(
                    isPressing ? Color.gray300 :
                        isSelected ? Color.main500 : Color.black100
                )
            
            Rectangle()
                .fill(isSelected ? Color.main500 : Color.clear)
                .frame(height: 2)
                .padding(.horizontal, -Spacing.xs)
        }
        .padding(.horizontal, 18)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.1), value: isPressing)
    }
}

// MARK: - 상태관리용
private struct PressState {
    var startTime: Date?
    var timer: Timer?
}

private struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
