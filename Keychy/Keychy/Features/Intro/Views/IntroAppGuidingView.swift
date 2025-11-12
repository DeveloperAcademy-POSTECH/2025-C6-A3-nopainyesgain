//
//  IntroAppGuidingView.swift
//  Keychy
//
//  Created by 길지훈 on 11/12/25.
//

import SwiftUI

struct IntroAppGuidingView: View {
    @Bindable var viewModel: IntroViewModel
    @State private var currentPage = 0

    // 가이드 페이지 수
    private let totalPages = 2

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 페이지 뷰
                HStack {
                    backToolbarItem
                    Spacer()
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        guidePage(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // 커스텀 인디케이터
                pageIndicator
            }
            .background(.white100)
        }
    }
}


extension IntroAppGuidingView {
    /// 페이지 콘텐츠
    private func guidePage(index: Int) -> some View {
        VStack(spacing: 14) {
            // 제목
            Text(guidingLabel(for: index))
                .typography(.suit20B)
                .foregroundStyle(.black100)
                .multilineTextAlignment(.center)

            // 이미지
            switch index {
            case 0:
                Image("homeGuiding")
            case 1:
                Image("collectionGuiding")
            default:
                Image("homeGuiding")
            }
        }
        .padding(.bottom, 16)
    }

    /// 설명 레이블
    private func guidingLabel(for index: Int) -> String {
        switch index {
        case 0: return "홈"
        case 1: return "보관함"
        default: return ""
        }
    }
    
    /// 페이지 인디케이터
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? .primary : Color.primary.opacity(0.3))
                    .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }
    
    /// X 버튼
    private var backToolbarItem: some View {
        CircleGlassButton(imageName: "dismiss_gray600") {
            viewModel.closeAppGuiding()
        }
        .padding(.leading, 26)
    }
}



