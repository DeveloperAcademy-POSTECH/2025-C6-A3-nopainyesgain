//
//  KeyringInfoInputView+TagManagement.swift
//  Keychy
//
//  Tag management and related components
//

import SwiftUI
import FirebaseFirestore

// MARK: - Tag Selection View
extension KeyringInfoInputView {
    var selectTagsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("태그")
                .typography(.suit16B)
                .foregroundStyle(.black100)

            ChipLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                Button {
                    sheetDetent = .height(76)
                    showAddTagAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18.75))
                        .foregroundStyle(.black100)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white100)
                                .stroke(.gray200, lineWidth: 1)
                        )
                }
                ForEach(availableTags, id: \.self) { tag in
                    ChipView(
                        title: tag,
                        isSelected: viewModel.selectedTags.contains(tag),
                        action: {
                            if viewModel.selectedTags.contains(tag) {
                                viewModel.selectedTags.removeAll { $0 == tag }
                            } else {
                                viewModel.selectedTags.append(tag)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Add Tag Alert
extension KeyringInfoInputView {
    var addNewTagAlertView: some View {
        VStack(spacing: 26) {
            VStack(spacing: 11) {
                Text("태그 만들기")
                    .font(.system(size: 20, weight: .semibold))
                TextField("태그 이름을 입력하세요", text: $newTagName)
            }
            HStack(spacing: 10) {
                Button {
                    newTagName = ""
                    showAddTagAlert = false
                    showTagNameAlreadyExistsToast = false
                    showTagNameEmptyToast = false
                    sheetDetent = .height(measuredSheetHeight)
                } label: {
                    Text("취소")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 50)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                }

                Button {
                    if newTagName.isEmpty {
                        showTagNameEmptyToast = true
                    } else {
                        if availableTags.contains(newTagName) {
                            showTagNameEmptyToast = false
                            showTagNameAlreadyExistsToast = true
                        } else {
                            // Firebase에 태그 추가
                            addTagToFirebase(tagName: newTagName)
                            newTagName = ""
                            showAddTagAlert = false
                            showTagNameAlreadyExistsToast = false
                            showTagNameEmptyToast = false
                            sheetDetent = .height(measuredSheetHeight)
                        }
                    }
                } label: {
                    Text("추가")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 50)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red)
                        )
                }
            }
            if showTagNameEmptyToast {
                Text("태그 이름을 입력해주세요.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red)
            }
            if showTagNameAlreadyExistsToast {
                Text("이미 사용 중인 태그 이름입니다.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 1)
        )
    }
}

// MARK: - Firebase Tag Management
extension KeyringInfoInputView {
    /// Firebase에 태그 추가
    func addTagToFirebase(tagName: String) {
        guard let userId = userManager.currentUser?.id else { return }

        Task {
            do {
                try await Firestore.firestore()
                    .collection("User")
                    .document(userId)
                    .updateData([
                        "tags": FieldValue.arrayUnion([tagName])
                    ])

                // UserManager 업데이트
                await refreshUserData()
            } catch {
                print("태그 추가 실패: \(error.localizedDescription)")
            }
        }
    }

    /// UserManager의 유저 데이터 새로고침
    func refreshUserData() async {
        guard let userId = userManager.currentUser?.id else { return }

        await withCheckedContinuation { continuation in
            userManager.loadUserInfo(uid: userId) { _ in
                continuation.resume()
            }
        }
    }
}

// MARK: - ChipView (재사용 컴포넌트)
struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .typography(.suit14M)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.mainOpacity15 : Color.gray50)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.main700 : Color.gray300, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? Color.main700 : Color.gray300)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ChipLayout
struct ChipLayout: Layout {
    var verticalSpacing: CGFloat
    var horizontalSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if currentRowWidth + viewSize.width > (proposal.width ?? .infinity) {
                totalHeight += currentRowHeight + verticalSpacing
                currentRowWidth = 0
                currentRowHeight = 0
            }

            currentRowWidth += viewSize.width + horizontalSpacing
            currentRowHeight = max(currentRowHeight, viewSize.height)
        }

        totalHeight += currentRowHeight
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)

            if currentX + viewSize.width > bounds.maxX {
                currentX = bounds.minX
                currentY += maxHeightInRow + verticalSpacing
                maxHeightInRow = 0
            }

            view.place(at: CGPoint(x: currentX, y: currentY), anchor: .topLeading, proposal: .unspecified)
            currentX += viewSize.width + horizontalSpacing
            maxHeightInRow = max(maxHeightInRow, viewSize.height)
        }
    }
}
