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
    private let totalPages = 3
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    TabView(selection: $currentPage) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            guidePage(index: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    .frame(height: geometry.size.height * 0.75)

                    pageIndicator
                        .padding(.top, 16)

                    Spacer()

                    // 다음버튼
                    nextBtn
                }
                .background(.white100)
            }
        }
    }
}


extension IntroAppGuidingView {
    /// 페이지 콘텐츠
    private func guidePage(index: Int) -> some View {
        VStack(spacing: 0) {
            // 제목
            Text(guidingLabel(for: index))
                .typography(.suit20B)
                .foregroundStyle(.black100)
                .multilineTextAlignment(.center)
                .padding(.bottom, 29)

            // 이미지
            switch index {
            case 0:
                Image("homeGuiding")
                    .resizable()
                    .scaledToFit()
            case 1:
                Image("collectionGuiding")
                    .resizable()
                    .scaledToFit()
            case 2:
                Image("collectionGuiding")
                    .resizable()
                    .scaledToFit()
            default:
                Image("collectionGuiding")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    /// 설명 레이블
    private func guidingLabel(for index: Int) -> String {
        switch index {
        case 0: return "나만의 키링을 모아보고\n키링을 터치해서 가지고 놀아보세요"
        case 1: return "키링을 모으고 즐기며 나누는 공간이에요\n "
        case 2: return "키링을 만들고 꾸미는 데 필요한 것들이\n모여 있는 제작 공간이에요"
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
                    .padding(.vertical, 8)
            }
        }
    }
    
    /// 다음 버튼
    private var nextBtn: some View {
        Button {
            if currentPage < totalPages - 1 {
                currentPage += 1
            } else {
                viewModel.closeAppGuiding()
            }
        } label: {
            Text(currentPage < totalPages - 1 ? "다음" : "Keychy!")
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

