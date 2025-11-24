//
//  SpeechBubbleFramePreviewView.swift
//  Keychy
//
//  Created by 길지훈 on 11/24/25.
//
//  말풍선 템플릿 프레임 미리보기 뷰 (중앙 씬 영역)
//

import SwiftUI
import NukeUI
import Nuke

struct SpeechBubbleFramePreviewView: View {
    @Bindable var viewModel: SpeechBubbleVM
    let onSceneReady: () -> Void

    @FocusState private var isTextFieldFocused: Bool
    @State private var isFrameLoaded: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠
                VStack {
                    ZStack(alignment: .top) {
                        // 프레임 + 텍스트 영역
                        VStack {
                            Spacer()
                                .frame(height: 126)  // 134 → 126 (8만큼 위로)

                            compositionView
                        }

                        // frameChain 이미지 (위에 겹침)
                        Image("frameChain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 168)
                .opacity(isFrameLoaded ? 1 : 0)

                // 로딩 중일 때
                if !isFrameLoaded {
                    LoadingAlert(type: .short, message: nil)
                }
            }
        }
        .dismissKeyboardOnTap()
        .onAppear {
            // 일반 SwiftUI View는 즉시 준비 완료
            onSceneReady()
        }
        .onChange(of: viewModel.selectedFrame) { oldValue, newValue in
            // 프레임 타입이 변경되면 기존 텍스트를 새 제약에 맞게 재조정
            // 줄바꿈 제거 후 다시 적용 (타입 변경 시 모든 텍스트 유지)
            let textWithoutNewlines = viewModel.inputText.replacingOccurrences(of: "\n", with: "")
            viewModel.inputText = applyTextConstraints(textWithoutNewlines)
        }
    }

    // MARK: - Composition View

    /// 프레임 + 텍스트 합성 미리보기
    @ViewBuilder
    private var compositionView: some View {
        ZStack(alignment: .center) {
            if let frame = viewModel.selectedFrame {
                LazyImage(url: URL(string: frame.frameURL)) { state in
                    if let image = state.image {
                        ZStack(alignment: .center) {
                            // 1. 프레임 이미지 (원본 크기)
                            image
                                .resizable()
                                .scaledToFit()

                            // 2. 텍스트 입력 필드 (중앙에 오버레이)
                            textInputField
                                .offset(y: frame.textOffsetY ?? 0)
                        }
                        .onAppear {
                            isFrameLoaded = true
                        }
                    }
                }
                .onDisappear {
                    isFrameLoaded = false
                }
            }
        }
    }

    // MARK: - Text Input Field

    /// 텍스트 입력 필드 (프레임 타입별 제약 적용)
    @ViewBuilder
    private var textInputField: some View {
        ZStack {
            // Placeholder (텍스트 비어있을 때만 표시)
            if viewModel.inputText.isEmpty {
                Text("텍스트를\n입력해주세요")
                    .typography(.gulim20R)
                    .foregroundStyle(Color.gray300)
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }

            // TextField
            TextField("", text: $viewModel.inputText, axis: .vertical)
                .typography(.gulim20R)
                .foregroundStyle(viewModel.selectedTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(viewModel.maxLines)
                .focused($isTextFieldFocused)
                .onChange(of: viewModel.inputText) { oldValue, newValue in
                    // 글자 수 제한 적용
                    viewModel.inputText = applyTextConstraints(newValue)
                }
                .padding(.vertical, 3.5)
        }
        .padding()
    }

    // MARK: - Helper Methods

    /// 텍스트 제약 적용 (줄당 글자 수 + 최대 줄 수 + 자동 줄바꿈)
    private func applyTextConstraints(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [String] = []

        for line in lines {
            let lineStr = String(line)

            // 빈 줄은 그대로 추가 (수동 엔터 허용)
            if lineStr.isEmpty {
                result.append("")
                if result.count >= viewModel.maxLines {
                    break
                }
                continue
            }

            // 현재 줄이 maxCharsPerLine을 초과하면 자동으로 쪼개기
            var remaining = lineStr
            while !remaining.isEmpty && result.count < viewModel.maxLines {
                let chunk = String(remaining.prefix(viewModel.maxCharsPerLine))
                result.append(chunk)
                remaining = String(remaining.dropFirst(viewModel.maxCharsPerLine))
            }

            // 최대 줄 수 도달 시 중단
            if result.count >= viewModel.maxLines {
                break
            }
        }

        // 최대 줄 수 제한
        return result.prefix(viewModel.maxLines).joined(separator: "\n")
    }
}

#Preview {
    SpeechBubbleFramePreviewView(
        viewModel: SpeechBubbleVM(),
        onSceneReady: {}
    )
    .environment(UserManager.shared)
}
