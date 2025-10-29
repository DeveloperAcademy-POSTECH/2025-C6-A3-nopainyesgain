//
//  KeyringInfoInputView.swift
//  KeytschPrototype
//
//  키링 정보 입력 화면
//  - 모든 템플릿에서 공통으로 사용 가능
//

import SwiftUI
import SpriteKit
import Combine

struct KeyringInfoInputView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String
    let nextRoute: WorkshopRoute
    
    // TODO: - User 모델 및 파이어베이스 연동 시 삭제
    @State private var availableTags = ["또치", "싱싱", "고양이"]
    
    @State private var textCount: Int = 0
    @State private var memoTextCount: Int = 0
    @State private var showAddTagAlert: Bool = false
    @State private var showTagNameAlreadyExistsToast: Bool = false
    @State private var showTagNameEmptyToast: Bool = false
    @State private var newTagName: String = ""
    @State private var keyboardHandler = KeyboardResponder()
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            VStack {
                keyringScene
                sheetView
            }

            if showAddTagAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                addNewTagAlertView
                    .padding(.horizontal, 25)
            }
        }
        .safeAreaInset(edge: .bottom) {
          Color.clear.frame(height: keyboardHandler.currentHeight)
        }
        .navigationTitle(navigationTitle)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - KeyringScene Section
extension KeyringInfoInputView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, minHeight: 500)
    }
}

//MARK: - 시트 뷰
extension KeyringInfoInputView {
    private var sheetView: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("정보")
                    .font(.subheadline)
                textNameView
                textMemoView
                selectTagsView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 30)
        }
    }
}

//MARK: - 이름 입력 뷰
extension KeyringInfoInputView {
    private var textNameView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("이름")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black)
            }
            HStack {
                TextField(
                    "이름을 입력해주세요",
                    text: $viewModel.nameText
                )
                .focused($isFocused)
                .onChange(of: viewModel.nameText) { _, newValue in
                    let regexString = "[^가-힣\\u3131-\\u314E\\u314F-\\u3163a-zA-Z0-9\\s]+"
                    var sanitized = newValue.replacingOccurrences(of: regexString, with: "", options: .regularExpression)

                    if sanitized.count > viewModel.maxTextCount {
                        sanitized = String(sanitized.prefix(viewModel.maxTextCount))
                    }

                    if sanitized != viewModel.nameText {
                        viewModel.nameText = sanitized
                    }

                    textCount = viewModel.nameText.count
                }
                .font(.system(size: 16, weight: .medium))
                Text("\(textCount) / \(viewModel.maxTextCount)")
                    .font(.system(size: 14, weight: .light))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
            )
        }
    }
}

//MARK: - 메모 입력
extension KeyringInfoInputView {
    private var textMemoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("메모")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)

            ZStack(alignment: .topLeading) {
                if viewModel.memoText.isEmpty {
                    Text("메모(선택)")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .font(.system(size: 16, weight: .medium))
                }
                TextEditor(text: $viewModel.memoText)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 80, maxHeight: 150)
                    .onChange(of: viewModel.memoText) { _, newValue in
                        memoTextCount = newValue.count
                        if newValue.count > viewModel.maxMemoCount {
                            viewModel.memoText = String(newValue.prefix(viewModel.maxMemoCount))
                            memoTextCount = viewModel.maxMemoCount
                        }
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.1))
            )
        }
    }
}

//MARK: - 태그 선택 화면
extension KeyringInfoInputView {
    private var selectTagsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("태그")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)

            ChipLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                Button {
                    showAddTagAlert = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(Color.white)
                                .shadow(radius: 1)
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

//MARK: - 툴바
extension KeyringInfoInputView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
            }
        }
    }

    private var nextToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("완료") {
                dismissKeyboard()
                router.push(nextRoute)
                showAddTagAlert = false
                showTagNameAlreadyExistsToast = false
                showTagNameEmptyToast = false
                viewModel.createdAt = Date()
            }
            .disabled(viewModel.nameText.isEmpty)
        }
    }
}

// MARK: - 태그 추가 Alert
extension KeyringInfoInputView {
    private var addNewTagAlertView: some View {
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
                            availableTags.append(newTagName)
                            newTagName = ""
                            showAddTagAlert = false
                            showTagNameAlreadyExistsToast = false
                            showTagNameEmptyToast = false
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

// MARK: - ChipView (재사용 컴포넌트)
struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.primary.opacity(0.15) : Color.gray.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.primary : Color.gray.opacity(0.4), lineWidth: 1)
                )
                .foregroundStyle(isSelected ? Color.primary : Color.gray)
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

// MARK: - KeyboardResponder
@Observable
final class KeyboardResponder {
  private var notificationCenter: NotificationCenter
  private(set) var currentHeight: CGFloat = 0

  init(center: NotificationCenter = .default) {
    notificationCenter = center
    notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }

  deinit {
    notificationCenter.removeObserver(self)
  }

  @objc func keyBoardWillShow(notification: Notification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      currentHeight = keyboardSize.height
    }
  }

  @objc func keyBoardWillHide(notification: Notification) {
    currentHeight = 0
  }
}
