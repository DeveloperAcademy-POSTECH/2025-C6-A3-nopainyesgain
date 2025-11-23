//
//  Showcase25BoardView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI
import NukeUI

struct Showcase25BoardView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>
    @State private var viewModel = Showcase25BoardViewModel()

    // 그리드 설정
    private let gridColumns = 10
    private let gridRows = 10
    private let cellAspectRatio: CGFloat = 2.0 / 3.0  // 가로:세로 = 2:3

    // 줌 설정
    // 최대 축소: 가로 6개 보임 -> 셀 너비 = 화면너비 / 6
    // 최대 확대: 가로 2개 보임 -> 셀 너비 = 화면너비 / 2
    // 확대 배율 = 6 / 2 = 3
    private let minZoom: CGFloat = 0.7
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
                initialZoom: initialZoom,
                onZoomChange: { zoom in
                    viewModel.currentZoom = zoom
                }
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
        let keyring = viewModel.keyring(at: index)

        return ZStack {
            // 셀 배경
            Rectangle()
                .fill(Color.white100)
                .border(Color.gray50, width: 0.5)

            if let keyring = keyring, !keyring.bodyImageURL.isEmpty {
                // 키링 이미지가 있는 경우
                LazyImage(url: URL(string: keyring.bodyImageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.error != nil {
                        // 로드 실패
                        Image(systemName: "photo")
                            .foregroundStyle(.gray300)
                    } else {
                        // 로딩 중
                        ProgressView()
                    }
                }
                .padding(8)
            } else {
                // 키링이 없는 경우 + 버튼
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
                .opacity(viewModel.showButtons ? 1 : 0)
                .disabled(!viewModel.showButtons)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showButtons)
            }
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
