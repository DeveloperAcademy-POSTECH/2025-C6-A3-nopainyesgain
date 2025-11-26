//
//  Showcase25BoardView+Grid.swift
//  Keychy
//
//  Created by rundo on 11/25/25.
//

import SwiftUI
import NukeUI

// MARK: - Grid 관련 Extension

extension Showcase25BoardView {
    // MARK: - Grid Cell

    func gridCell(index: Int) -> some View {
        let keyring = viewModel.keyring(at: index)
        let isMyKeyring = viewModel.isMyKeyring(at: index)
        let isBeingEditedByOthers = viewModel.isBeingEditedByOthers(at: index)

        return ZStack {

            if let keyring = keyring, !keyring.bodyImageURL.isEmpty {
                // 키링 이미지가 있는 경우
                keyringImageView(keyring: keyring, index: index)
            } else if isBeingEditedByOthers, let editingKeyring = keyring {
                // 다른 사람이 수정 중인 경우
                let maskedName = viewModel.maskedNickname(editingKeyring.editingUserNickname)
                ZStack {
                    LoadingAlert(type: .short, message: nil)
                        .scaleEffect(0.5)
                    VStack {
                        Spacer()
                        Text("\(maskedName)님\n수정중")
                            .typography(.notosans10M)
                            .foregroundStyle(.gray300)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 10)
                }
            } else {
                // 키링이 없는 경우 + 버튼
                Button {
                    // 위치 체크: 범위 안에 있을 때만 시트 열기
                    if let targetLocation = FestivalLocationManager.shared.currentTargetLocation,
                       locationManager.isLocationActive(targetLocation) {
                        viewModel.selectedGridIndex = index
                        Task {
                            await viewModel.updateIsEditing(at: index, isEditing: true)
                        }
                        withAnimation(.easeInOut) {
                            viewModel.showKeyringSheet = true
                        }
                    } else {
                        viewModel.showLocationToast()
                    }
                } label: {
                    Image(.plus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .padding(3)
                .glassEffect(.clear.interactive(), in: .circle)
                .opacity(viewModel.showButtons ? 1 : 0)
                .disabled(!viewModel.showButtons)
                .animation(.easeInOut(duration: 0.2), value: viewModel.showButtons)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .overlay(alignment: .topTrailing) {
            // 내 키링 표시 (우측 상단)
            if isMyKeyring {
                Circle()
                    .fill(Color.main500)
                    .frame(width: 6, height: 6)
                    .padding(5)
            }
        }
        .overlay(alignment: .top) {
            // 키링 행거
            Image(.festivalHanger)
                .resizable()
                .scaledToFit()
                .frame(width: 8, height: 8)
                .padding(.top, 10)
        }
    }

    // MARK: - Keyring Image View

    @ViewBuilder
    func keyringImageView(keyring: ShowcaseFestivalKeyring, index: Int) -> some View {
        let isMyKeyring = viewModel.isMyKeyring(at: index)

        // 캐시된 이미지 확인 (keyringId = Firestore documentId)
        let cachedImageData = KeyringImageCache.shared.load(for: keyring.keyringId)

        let imageView = Group {
            if let imageData = cachedImageData, let uiImage = UIImage(data: imageData) {
                // 캐시된 이미지 사용
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // 캐시에 없으면 URL로 로드
                LazyImage(url: URL(string: keyring.bodyImageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.error != nil {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray300)
                    } else {
                        LoadingAlert(type: .short, message: nil)
                            .scaleEffect(0.5)
                    }
                }
            }
        }

        // 내 키링인 경우에만 컨텍스트 메뉴 표시
        if isMyKeyring {
            imageView
                .onTapGesture {
                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
                }
                .contextMenu {
                    Button {
                        viewModel.selectedGridIndex = index
                        withAnimation(.easeInOut) {
                            viewModel.showKeyringSheet = true
                        }
                    } label: {
                        Label("교체", systemImage: "arrow.left.arrow.right")
                    }

                    Button {
                        gridIndexToDelete = index
                        showDeleteAlert = true
                    } label: {
                        Label("회수", systemImage: "arrow.counterclockwise")
                    }
                }
        } else {
            // 남의 키링인 경우 탭 제스처만
            imageView
                .onTapGesture {
                    fetchAndNavigateToKeyringDetail(keyringId: keyring.keyringId)
                }
        }
    }
}
