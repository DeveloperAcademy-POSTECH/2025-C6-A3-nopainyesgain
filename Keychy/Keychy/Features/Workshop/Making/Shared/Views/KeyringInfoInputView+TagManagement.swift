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
                    Image("Plus")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray50)
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

// MARK: - Add Tag Alert (Glass Style)
extension KeyringInfoInputView {
    var addNewTagAlertView: some View {
        VStack(spacing: 0) {
            // 타이틀
            Text("태그 추가하기")
                .typography(.suit17B)
                .foregroundStyle(.black100)
                .padding(.top, 14)
            
            // TextField
            TextField("태그 이름을 입력해주세요", text: $newTagName)
                .typography(.notosans15R)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white100)
                )
                .padding(.top, 21)
                .padding(.bottom, 5)
                .onChange(of: newTagName) { oldValue, newValue in
                    if newValue.count > 10 {
                        newTagName = String(newValue.prefix(10))
                    }
                    showTagNameAlreadyExistsToast = availableTags.contains(newValue)
                }
            
            HStack {
                Text(showTagNameAlreadyExistsToast ? "이미 사용 중인 태그 이름입니다." : "")
                    .typography(.suit14M)
                    .foregroundStyle(.error)
                    .opacity(showTagNameAlreadyExistsToast ? 1 : 0)
                
                Spacer()
            }
            .padding(.bottom, 20)
            
            
            // 버튼들
            HStack(spacing: 16) {
                // 취소 버튼
                Button {
                    newTagName = ""
                    showAddTagAlert = false
                    showTagNameAlreadyExistsToast = false
                    sheetDetent = .height(measuredSheetHeight)
                } label: {
                    Text("취소")
                        .typography(.suit17SB)
                        .foregroundStyle(.black100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.black10)
                        )
                }
                .buttonStyle(.plain)
                
                // 추가 버튼
                Button {
                    if !showTagNameAlreadyExistsToast, !newTagName.isEmpty {
                        addTagToFirebase(tagName: newTagName)
                        newTagName = ""
                        showAddTagAlert = false
                        showTagNameAlreadyExistsToast = false
                        showTagNameEmptyToast = false
                        sheetDetent = .height(measuredSheetHeight)
                    }
                } label: {
                    Text("추가")
                        .typography(.suit17B)
                        .foregroundStyle(.white100)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(.main500)
                        )
                    
                }
                .buttonStyle(.plain)
                .disabled(newTagName.isEmpty || showTagNameAlreadyExistsToast)
            }
        }
        .padding(14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 230)
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
                
                // 새로 추가한 태그를 자동으로 선택
                await MainActor.run {
                    if !viewModel.selectedTags.contains(tagName) {
                        viewModel.selectedTags.append(tagName)
                    }
                }
                
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
                .typography(isSelected ? .malang15B : .malang15R)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? .mainOpacity15 : .gray50)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? .main500 : .clear, lineWidth: 1.5)
                )
                .foregroundStyle(isSelected ? .main500 : .gray400)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .frame(height: 35)
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
