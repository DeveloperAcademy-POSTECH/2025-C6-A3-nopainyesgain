//
//  WorkshopCurrentUsedSection.swift
//  Keychy
//
//  Created by rundo on 11/3/25.
//

import SwiftUI

// MARK: - My Collection Section

extension WorkshopView {
    /// 내 아이템 섹션 (끝까지 만들었던 키링만 표시)
    var CurrentUsedSection: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
            
                Text("최근 사용 템플릿")
                    .typography(.suit16B)
                    .foregroundColor(.black.opacity(0.7))

                Spacer()
            }

            // 최근 사용한 탬플리 리스트
            Group {
                if viewModel.isLoading {
                    loadingUsedTemplatesView
                    
                    Spacer()
                    
                } else {
                    if viewModel.currentUsedTemplates.isEmpty {
                        emptyOwnedView
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(viewModel.currentUsedTemplates) { template in
                                    CurrentUsedCard(item: template, router: router, viewModel: viewModel)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    /// 빈 최근 사용한 템플릿 뷰
    var emptyOwnedView: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("키링을 만들면 최근 사용한 템플릿이 이곳에 표시돼요.")
                .typography(.suit13SB)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 135)
        .padding(.bottom, 1)
        .background(.white70)
        .cornerRadius(10)
    }

    /// 최근 사용한 템플릿 뷰 로딩
    var loadingUsedTemplatesView: some View {
        HStack(spacing: 7) {
            SkeletonBox(width: 112, height: 112)
                .cornerRadius(10)
            SkeletonBox(width: 112, height: 112)
                .cornerRadius(10)
            SkeletonBox(width: 112, height: 112)
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }
}
