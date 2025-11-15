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
                
                // 커스텀 인디케이터
                pageIndicator
                    .safeAreaPadding(.top, 106)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        guidePage(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 다음버튼
                nextBtn
            }
            .background(.white100)
        }
    }
}


extension IntroAppGuidingView {
    /// 페이지 콘텐츠
    private func guidePage(index: Int) -> some View {
        VStack(spacing: 63) {
            // 제목
            Text(guidingLabel(for: index))
                .typography(.suit20B)
                .foregroundStyle(.black100)
                .multilineTextAlignment(.center)
            
            // 이미지
            switch index {
            case 0:
                Rectangle()
                    .frame(width: 401, height: 409)
                    .foregroundStyle(.gray50)
            case 1:
                Rectangle()
                    .frame(width: 401, height: 409)
                    .foregroundStyle(.gray50)
            default:
                Rectangle()
                    .frame(width: 401, height: 409)
                    .foregroundStyle(.gray50)
            }
        }
    }
    
    /// 설명 레이블
    private func guidingLabel(for index: Int) -> String {
        switch index {
        case 0: return "홈에서는 어쩌고 저쩌고 라이팅"
        case 1: return "보관함에서는 어쩌고 저쩌고 라이팅"
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
    private var nextBtn: some View {
        Button {
            viewModel.closeAppGuiding()
        } label: {
            Text("다음")
                .frame(maxWidth: .infinity)
                .typography(.suit17B)
                .padding(.vertical, 7.5)
        }
        .padding(.horizontal, 34)
        .buttonStyle(.glassProminent)
        .tint(.main500)
        .foregroundStyle(.white100)
    }
}

