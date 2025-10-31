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
import FirebaseFirestore

struct KeyringInfoInputView<VM: KeyringViewModelProtocol>: View {
    @Bindable var router: NavigationRouter<WorkshopRoute>
    @Bindable var viewModel: VM
    let navigationTitle: String
    let nextRoute: WorkshopRoute
    
    // UserManager 주입
    var userManager: UserManager = UserManager.shared
    
    // Firebase User의 tags 사용
    private var availableTags: [String] {
        userManager.currentUser?.tags ?? []
    }
    
    @State private var textCount: Int = 0
    @State private var memoTextCount: Int = 0
    @State private var showAddTagAlert: Bool = false
    @State private var showTagNameAlreadyExistsToast: Bool = false
    @State private var showTagNameEmptyToast: Bool = false
    @State private var newTagName: String = ""
    @State private var keyboardHandler = KeyboardResponder()
    @State private var sheetDetent: PresentationDetent = .height(76)
    @State private var showSheet: Bool = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray50
                    .ignoresSafeArea()

                keyringScene
                    .frame(height: availableSceneHeight)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(calculatedZoomScale)
                    .position(x: geometry.size.width / 2, y: availableSceneHeight / 2)
                    .animation(.easeInOut(duration: 0.3), value: sheetDetent)
                    .padding(.top, 8)

                if showAddTagAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    addNewTagAlertView
                        .padding(.horizontal, 25)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(navigationTitle)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
        .sheet(isPresented: $showSheet) {
            infoSheet
                .presentationDetents([.height(76), .height(395)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(395)))
                .interactiveDismissDisabled()
        }
        .toolbar {
            backToolbarItem
            nextToolbarItem
        }
        .dismissKeyboardOnTap()
    }

    // 바텀시트 높이 제외한 사용 가능한 씬 높이
    private var availableSceneHeight: CGFloat {
        sheetDetent == .height(76) ? 700 : 600
    }

    // 씬 줌 스케일 계산 (높이에 따라 선형 보간)
    private var calculatedZoomScale: CGFloat {
        let maxHeight: CGFloat = 700
        let minHeight: CGFloat = 600
        let maxZoom: CGFloat = 1.0
        let minZoom: CGFloat = 0.85

        // 선형 보간
        let ratio = (availableSceneHeight - minHeight) / (maxHeight - minHeight)
        return minZoom + (maxZoom - minZoom) * ratio
    }
}

// MARK: - KeyringScene Section
extension KeyringInfoInputView {
    private var keyringScene: some View {
        KeyringSceneView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(sheetDetent == .height(76))
    }
}

//MARK: - 시트 뷰
extension KeyringInfoInputView {
    private var infoSheet: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("정보")
                            .typography(.suit15B25)
                        Spacer()
                    }
                    .padding(.top, 29)
                    .animation(.easeInOut(duration: 0.35), value: sheetDetent)
                    
                    if sheetDetent == .height(395) {
                        textNameView
                            .padding(.bottom, 22)
                        
                        textMemoView
                            .padding(.bottom, 22)
                        
                        selectTagsView
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(sheetDetent == .height(395) ? .white100 : Color.clear)
        .shadow(
            color: Color.black.opacity(0.18),
            radius: 37.5,
            x: 0,
            y: -15
        )
        .animation(.easeInOut(duration: 0.3), value: sheetDetent)
    }
}

//MARK: - 이름 입력 뷰
extension KeyringInfoInputView {
    private var textNameView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이름 (필수)")
                .typography(.suit16B)
                .foregroundStyle(.black100)
            
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
                .typography(.suit16M25)
                
                Text("\(textCount) / \(viewModel.maxTextCount)")
                    .typography(.suit16M25)
                    .foregroundStyle(.gray300)
            }
            .padding(.vertical, 13.5)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
            )
        }
    }
}

//MARK: - 메모 입력
extension KeyringInfoInputView {
    private var textMemoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("메모")
                .typography(.suit16B)
                .foregroundStyle(.black100)
            
            ZStack(alignment: .topLeading) {
                if viewModel.memoText.isEmpty {
                    Text("메모(선택)")
                        .typography(.suit16M25)
                        .foregroundColor(.gray300)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                }

                TextEditor(text: $viewModel.memoText)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .typography(.suit16M25)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray50)
            )
        }
    }
}

//MARK: - 태그 선택 화면
extension KeyringInfoInputView {
    private var selectTagsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("태그")
                .typography(.suit16B)
                .foregroundStyle(.black100)
            
            ChipLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                Button {
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
                showSheet = false
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
                            // Firebase에 태그 추가
                            addTagToFirebase(tagName: newTagName)
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


// MARK: - Firebase Tag 추가
extension KeyringInfoInputView {
    /// Firebase에 태그 추가
    private func addTagToFirebase(tagName: String) {
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
    private func refreshUserData() async {
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
