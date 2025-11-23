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
        }
        .padding()
    }

    // MARK: - Helper Methods

    /// 텍스트 제약 적용 (줄당 글자 수 + 최대 줄 수)
    private func applyTextConstraints(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        // 최대 줄 수 초과 방지
        if lines.count > viewModel.maxLines {
            return lines.prefix(viewModel.maxLines).joined(separator: "\n")
        }

        // 각 줄의 글자 수 제한
        let constrainedLines = lines.map { line in
            String(line.prefix(viewModel.maxCharsPerLine))
        }

        return constrainedLines.joined(separator: "\n")
    }
}

#Preview {
    SpeechBubbleFramePreviewView(
        viewModel: SpeechBubbleVM(),
        onSceneReady: {}
    )
    .environment(UserManager.shared)
}
