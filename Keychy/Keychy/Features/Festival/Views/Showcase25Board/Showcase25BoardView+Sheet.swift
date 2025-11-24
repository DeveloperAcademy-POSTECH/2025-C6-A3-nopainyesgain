//
//  Showcase25BoardView+Sheet.swift
//  Keychy
//
//  Created by rundo on 11/24/25.
//

import SwiftUI

// MARK: - Delete Keyring Alert Modifier

struct DeleteKeyringAlertModifier: ViewModifier {
    @Binding var showDeleteAlert: Bool
    @Binding var gridIndexToDelete: Int?
    var viewModel: Showcase25BoardViewModel

    func body(content: Content) -> some View {
        content
            .alert("키링 회수", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {
                    gridIndexToDelete = nil
                }
                Button("확인", role: .destructive) {
                    if let index = gridIndexToDelete {
                        Task {
                            await viewModel.deleteShowcaseKeyring(at: index)
                        }
                    }
                    gridIndexToDelete = nil
                }
            } message: {
                Text("정말 키링을 회수하시겠습니까?")
            }
    }
}

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
                        // Festival에서 Workshop으로 가는 경우 플래그 설정
                        dismissSheet()
                        viewModel.isFromFestivalTab = true

                        // Workshop에서 완료 후 다시 돌아올 콜백 설정
                        viewModel.onKeyringCompleteFromFestival = { workshopRouter in
                            // Workshop router를 reset하고 showcase25BoardView로 이동
                            workshopRouter.reset()
                            workshopRouter.push(.showcase25BoardView)
                        }

                        onNavigateToWorkshop?(.workshopTemplates)
                    } label: {
                        Text("+ 만들기")
                            .typography(.suit16M)
                            .foregroundStyle(.main500)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // 완료 버튼
                    Button {
                        confirmSelection()
                    } label: {
                        Text("완료")
                            .typography(.suit15M)
                            .foregroundStyle(viewModel.selectedKeyringForUpload != nil ? .main500 : .gray300)
                    }
                    .buttonStyle(.plain)
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

        // 시트 닫고 출품 확인 팝업 표시
        withAnimation(.easeInOut) {
            viewModel.showKeyringSheet = false
        }
        showSubmitPopup = true
    }

    func executeSubmit() {
        guard let keyring = viewModel.selectedKeyringForUpload else { return }
        let gridIndex = viewModel.selectedGridIndex

        // 선택 초기화
        viewModel.selectedKeyringForUpload = nil

        // 업로드는 백그라운드에서 진행
        Task {
            await viewModel.addOrUpdateShowcaseKeyring(
                at: gridIndex,
                with: keyring
            )
        }
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
