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
    let editableCategories: Set<String>  // 편집 가능한 카테고리들 (전체 제외)
    
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
    @State private var isPressing: Bool = false
    @State private var longPressTriggered: Bool = false
    @State private var pressStartTime: Date?
    @State private var longPressTimer: Timer?
    @State private var styleTimer: Timer?
    @State private var initialTouchLocation: CGPoint = .zero
    @State private var hasMoved: Bool = false
    
    var body: some View {
        // 기존 CategoryTabBar 스타일
        VStack(spacing: Spacing.sm) {
            Text(title)
                .typography(
                    isPressing ? .suit17B :
                    isSelected ? .suit15B25 : .suit15SB25
                )
                .foregroundStyle(
                    isPressing ? Color.gray300 :
                    isSelected ? Color.main500 : Color.black100
                )
            
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
        // Long Press Gesture
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // 첫 터치
                    if pressStartTime == nil {
                        pressStartTime = Date()
                        initialTouchLocation = value.location
                        longPressTriggered = false
                        hasMoved = false
                        
                        // 편집 가능한 태그만 누르는 중 스타일 적용
                        if isEditable {
                            styleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                                if !hasMoved && !longPressTriggered {
                                    isPressing = true
                                }
                            }
                        }
                        
                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            // 편집 가능하고, 아직 long press 안 됐고, 안 움직였으면
                            if isEditable && !longPressTriggered && !hasMoved {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                onLongPress(buttonFrame)
                                longPressTriggered = true
                            } else {
                                // long press 안 되면 스타일 원복
                                isPressing = false
                            }
                        }
                    }
                    
                    let dragDistance = hypot(
                        value.location.x - initialTouchLocation.x,
                        value.location.y - initialTouchLocation.y
                    )
                    
                    // 10pt 이상 움직이면 스크롤로 간주
                    if dragDistance > 10 {
                        hasMoved = true
                        cancelPress()
                    }
                }
                .onEnded { value in
                    defer {
                        resetPress()
                    }
                    
                    // Long press가 실행되었으면 아무것도 안 함
                    guard !longPressTriggered else { return }
                    
                    // 움직였으면 (스크롤) 아무것도 안 함
                    guard !hasMoved else { return }
                    
                    // 드래그 거리 최종 체크
                    let dragDistance = hypot(
                        value.location.x - initialTouchLocation.x,
                        value.location.y - initialTouchLocation.y
                    )
                    
                    // 거의 안 움직이고 빠르게 뗐으면 탭
                    if dragDistance < 10, let startTime = pressStartTime {
                        let duration = Date().timeIntervalSince(startTime)
                        if duration < 0.3 {
                            onTap()
                        }
                    }
                }
        )
        .animation(.easeInOut(duration: 0.1), value: isPressing)
    }
    
    // Press 취소 (타이머만 취소, 상태는 유지)
    private func cancelPress() {
        styleTimer?.invalidate()
        styleTimer = nil
        longPressTimer?.invalidate()
        longPressTimer = nil
        isPressing = false
    }
    
    // 완전 초기화
    private func resetPress() {
        styleTimer?.invalidate()
        styleTimer = nil
        longPressTimer?.invalidate()
        longPressTimer = nil
        pressStartTime = nil
        isPressing = false
        longPressTriggered = false
        hasMoved = false
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
