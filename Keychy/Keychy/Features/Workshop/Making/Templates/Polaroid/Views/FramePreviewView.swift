//
//  FramePreviewView.swift
//  Keychy
//
//  폴라로이드 템플릿 프레임 미리보기 뷰 (중앙 씬 영역)
//

import SwiftUI

struct FramePreviewView: View {
    @Bindable var viewModel: PolaroidVM
    let onSceneReady: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경
                Color.gray100

                // 프레임 미리보기 (임시)
                VStack {
                    Text("프레임 미리보기")
                        .typography(.suit20B)
                        .foregroundStyle(.black100)

                    if let frame = viewModel.selectedFrame {
                        Text("선택된 프레임: \(frame.name)")
                            .typography(.suit14M)
                            .foregroundStyle(.gray500)
                    } else {
                        Text("프레임을 선택해주세요")
                            .typography(.suit14M)
                            .foregroundStyle(.gray400)
                    }
                }
            }
        }
        .task {
            // 뷰 계층이 완전히 준비될 때까지 약간 대기
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            // 씬이 준비되었음을 알림
            onSceneReady()
        }
    }
}
