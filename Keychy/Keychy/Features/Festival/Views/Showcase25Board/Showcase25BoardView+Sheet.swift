//
//  Showcase25BoardView+Sheet.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI

// MARK: - Sheet 관련 Extension

extension Showcase25BoardView {

    // MARK: - Keyring Selection Sheet

    var keyringSelectionSheet: some View {
        VStack(spacing: 18) {
            // 상단 바: 만들기 / 타이틀 / 완료
            
            ZStack(alignment: .center) {
                HStack {
                    // 만들기 버튼
                    Button {
                        dismissSheet()
                        viewModel.isFromFestivalTab = true

                        viewModel.onKeyringCompleteFromFestival = { workshopRouter in
                            workshopRouter.reset()
                            workshopRouter.push(.showcase25BoardView)
                        }

                        onNavigateToWorkshop?(.workshopTemplates)
                    } label: {
                        Text("+ 만들기")
                            .typography(.suit16M)
                            .foregroundStyle(.main500)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.main500.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(.main500.opacity(0.3), lineWidth: 1)
                    )
                    .glassEffect(.regular, in: .capsule)

                    Spacer()

                    // 완료 버튼
                    Button {
                        confirmSelection()
                    } label: {
                        Text("완료")
                            .typography(.suit15M)
                            .foregroundStyle(viewModel.selectedKeyringForUpload != nil ? .white : .gray400)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedKeyringForUpload != nil ? .main500 : .gray50)
                    )
                    .glassEffect(.regular, in: .capsule)
                    .disabled(viewModel.selectedKeyringForUpload == nil)
                }
                
                Text("키링 선택")
                    .typography(.suit16B)
                    .foregroundStyle(.black100)
            }
            

            if viewModel.userKeyrings.isEmpty {
                // 키링이 없는 경우
                VStack {
                    Image(.emptyViewIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 77)
                    Text("공방에서 키링을 만들 수 있어요")
                        .typography(.suit15R)
                        .foregroundStyle(.black100)
                        .padding(.vertical, 15)
                }
                .padding(.bottom, 77)
                .padding(.top, 62)
                .frame(maxWidth: .infinity)
            } else {
                // 키링 목록
                ScrollView {
                    LazyVGrid(columns: sheetGridColumns, spacing: 10) {
                        ForEach(viewModel.userKeyrings, id: \.self) { keyring in
                            sheetKeyringCell(keyring: keyring)
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
        .frame(maxWidth: .infinity)
        .frame(height: screenHeight * sheetHeightRatio)
        .glassEffect(.regular, in: .rect)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
    }

    // MARK: - Sheet Actions

    func dismissSheet() {
        let gridIndex = viewModel.selectedGridIndex
        viewModel.selectedKeyringForUpload = nil
        withAnimation(.easeInOut) {
            viewModel.showKeyringSheet = false
        }
        // isEditing 상태 해제
        Task {
            await viewModel.updateIsEditing(at: gridIndex, isEditing: false)
        }
    }

    func confirmSelection() {
        guard viewModel.selectedKeyringForUpload != nil else { return }
        let gridIndex = viewModel.selectedGridIndex

        // 시트 닫고 출품 확인 팝업 표시
        withAnimation(.easeInOut) {
            viewModel.showKeyringSheet = false
        }
        showSubmitPopup = true

        // isEditing 상태 해제
        Task {
            await viewModel.updateIsEditing(at: gridIndex, isEditing: false)
        }
    }

    func handleSubmitConfirm() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showSubmitPopup = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            executeSubmit()
        }
    }

    func executeSubmit() {
        guard let keyring = viewModel.selectedKeyringForUpload else { return }
        let gridIndex = viewModel.selectedGridIndex

        // 선택 초기화
        viewModel.selectedKeyringForUpload = nil

        // 업로드 후 완료 알림 표시
        Task {
            await viewModel.addOrUpdateShowcaseKeyring(
                at: gridIndex,
                with: keyring
            )

            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSubmitCompleteAlert = true
                }
            }
        }
    }

    func handleDeleteConfirm() {
        guard let index = gridIndexToDelete else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showDeleteAlert = false
        }

        Task {
            await viewModel.deleteShowcaseKeyring(at: index)
        }
        gridIndexToDelete = nil
    }

    // MARK: - Sheet Keyring Cell

    func sheetKeyringCell(keyring: Keyring) -> some View {
        let isSelected = viewModel.selectedKeyringForUpload?.id == keyring.id

        return Button {
            // 선택 상태 토글
            if isSelected {
                viewModel.selectedKeyringForUpload = nil
            } else {
                viewModel.selectedKeyringForUpload = keyring
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    CollectionCellView(keyring: keyring)
                        .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                        .cornerRadius(10)

                    // 선택 표시
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.mainOpacity80, lineWidth: 2)
                            .frame(width: threeGridCellWidth, height: threeGridCellHeight)
                    }
                }

                Text(keyring.name)
                    .typography(isSelected ? .notosans14SB : .notosans14M)
                    .foregroundStyle(isSelected ? .main500 : .black100)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published)
    }
}
