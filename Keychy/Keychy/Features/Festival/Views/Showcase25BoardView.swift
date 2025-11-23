//
//  Showcase25BoardView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI

struct Showcase25BoardView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>

    // 그리드 설정
    private let gridColumns = 10
    private let gridRows = 10
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3

    // 줌 설정
    // 최대 축소: 가로 6개 보임 -> 셀 너비 = 화면너비 / 6
    // 최대 확대: 가로 2개 보임 -> 셀 너비 = 화면너비 / 2
    // 확대 배율 = 6 / 2 = 3
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 3.0
    private let initialZoom: CGFloat = 1.5  // 중간 정도로 시작

    // 그리드 전체 크기 계산 (최소 줌 기준)
    private var cellWidth: CGFloat {
        screenWidth / 6  // 최소 줌에서 6개 보임
    }

    private var cellHeight: CGFloat {
        cellWidth / cellAspectRatio  // 2:3 비율
    }

    private var gridWidth: CGFloat {
        cellWidth * CGFloat(gridColumns)
    }

    private var gridHeight: CGFloat {
        cellHeight * CGFloat(gridRows)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white100
                .ignoresSafeArea()

            // 확대/축소 가능한 그리드
            ZoomableScrollView(
                minZoom: minZoom,
                maxZoom: maxZoom,
                initialZoom: initialZoom
            ) {
                gridContent
            }
            .ignoresSafeArea()

            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        VStack(spacing: 0) {
            ForEach(0..<gridRows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<gridColumns, id: \.self) { col in
                        let index = row * gridColumns + col
                        gridCell(index: index)
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
    }

    // MARK: - Grid Cell

    private func gridCell(index: Int) -> some View {
        ZStack(alignment: .top) {
            // 셀 배경
            Rectangle()
                .fill(Color.white100)
                .border(Color.gray50, width: 0.5)

            // 중앙 상단 + 버튼
            Button {
                print("Grid cell \(index) tapped")
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white100)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.gray50)
                    )
            }
            .padding(.top, 12)
        }
        .frame(width: cellWidth, height: cellHeight)
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("쇼케이스 2025")
                .typography(.notosans17M)
        } trailing: {
            Spacer()
                .frame(width: 44, height: 44)
        }
    }
}
