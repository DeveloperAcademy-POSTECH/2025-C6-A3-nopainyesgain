//
//  KeyringEditView.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI
import SpriteKit

struct KeyringEditView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    @Bindable var viewModel: CollectionViewModel
    
    @State private var editedName: String
    @State private var editedMemo: String
    @State private var editedTags: [String]
    
    @State private var showAddTagAlert: Bool = false
    @State private var newTagName: String = ""
    @State private var showDuplicateTagError: Bool = false // 태그 중복검사용
    
    @State private var isLoading: Bool = true
    @State private var scene: KeyringCellScene?
    
    // MARK: - Profanity Filtering
    @State var validationMessage: String = ""
    @State var hasProfanity: Bool = false
    
    @FocusState private var focusedField: Field?
    
    let keyring: Keyring
    
    var userManager: UserManager = UserManager.shared

    var availableTags: [String] {
        userManager.currentUser?.tags ?? []
    }
    
    private var isCompleteEnabled: Bool {
        let nameNotEmpty = !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let noProfanity = !hasProfanity && validationMessage.isEmpty
        
        return nameNotEmpty && noProfanity
    }
    
    private var canEdit: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userUID") else {
            return false
        }
        return keyring.isEditable && keyring.authorId == currentUserId
    }
    
    enum Field: Hashable {
        case name
        case memo
    }
    
    // 초기값 설정
    init(router: NavigationRouter<CollectionRoute>, viewModel: CollectionViewModel, keyring: Keyring) {
        self.router = router
        self.viewModel = viewModel
        self.keyring = keyring
        
        _editedName = State(initialValue: keyring.name)
        _editedMemo = State(initialValue: keyring.memo ?? "")
        _editedTags = State(initialValue: keyring.tags)
    }

    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                keyringSection
                
                ScrollView {
                    VStack(spacing: 0) {
                        infoInputSection
                        
                        tagSection
                    }
                }
                .scrollIndicators(.hidden)
            }
            
            if showAddTagAlert {
                Color.black20
                    .ignoresSafeArea()
                
                TagInputPopup(
                    type: .add,
                    tagName: $newTagName,
                    availableTags: availableTags,
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAddTagAlert = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            newTagName = ""
                            showDuplicateTagError = false
                        }
                    },
                    onConfirm: { tag in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAddTagAlert = false
                        }
                        viewModel.addNewTag(uid: userManager.userUID, newTagName: tag)
                        newTagName = ""
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(200)
            }
        }
        .navigationTitle("정보 수정")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .withToast(position: .default)
        .toolbar {
            backToolbarItem
            completeToolbarItem
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 빈 공간 탭하면 키보드 내리기
            focusedField = nil
        }
    }
}

// MARK: - 툴바
extension KeyringEditView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(.backIcon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    private var completeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isCompleteEnabled {
                Button(role: .confirm, action: {
                    // 네트워크 체크
                    guard NetworkManager.shared.isConnected else {
                        ToastManager.shared.show()
                        return
                    }

                    viewModel.updateKeyring(
                        keyring: keyring,
                        name: editedName,
                        memo: editedMemo,
                        tags: editedTags
                    ) { success in
                        if success {
                            router.reset()
                            viewModel.showTabBar()
                        }
                    }
                }) {
                    Image(.recCheck)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.white100)
                        .frame(width: 32, height: 32)

                }
            }
            else {
                Button(action: {
                    // disabled
                }) {
                    Image(.recCheck)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.gray300)
                        .frame(width: 32, height: 32)

                }
                .disabled(true)
            }

        }
    }
}

// MARK: - 키링 모습 + 디자인 수정 버튼 섹션
extension KeyringEditView {
    private var keyringSection: some View {
        VStack {
            ZStack {
                SpriteView(
                    scene: createMiniScene(keyring: keyring),
                    options: [.allowsTransparency]
                )
                if isLoading {
                    Color.black20
                        .overlay {
                            VStack(spacing: 8) {
                                LoadingAlert(type: .short, message: nil)
                                    .scaleEffect(0.4)
                            }
                        }
                }
            }
            .frame(width: 100, height: 133)  // 표시될 최종 크기
            .cornerRadius(10)
            .allowsHitTesting(false)
            
            Button {
                // 디자인 수정 (이후 추가)
            } label: {
                Text("수정하기")
                    .typography(.suit14R18)
                    .foregroundColor(.main700)
            }
            .opacity(0.0)
        }
        .padding(.top, 13)
    }
    
    private func createMiniScene(keyring: Keyring) -> KeyringCellScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 175, height: 233),
            customBackgroundColor: .clear,
            zoomScale: 2.0,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        )
        scene.scaleMode = .aspectFill
        return scene
    }
}

// MARK: - 정보 입력 섹션 (이름 + 메모)
extension KeyringEditView {
    private var infoInputSection: some View {
        VStack(spacing: 25) {
            nameInputField
            
            if canEdit || !(keyring.memo?.isEmpty ?? true) {
                memoInputField
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 25)
    }
    
    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이름 (필수)")
                .typography(.suit16B)
            
            HStack {
                TextField("이름을 입력해주세요", text: $editedName)
                    .typography(.notosans16R)
                    .foregroundColor(.black100)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .tint(.main500)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .name)
                    .disabled(!canEdit)
                    .onChange(of: editedName) { newValue in
                        // 글자수 제한만 적용 (특수문자 허용)
                        var sanitized = newValue

                        if sanitized.count > 10 {
                            sanitized = String(sanitized.prefix(10))
                        }

                        if sanitized != editedName {
                            editedName = sanitized
                        }

                        // 욕설 체크
                        if editedName.isEmpty {
                            validationMessage = ""
                            hasProfanity = false
                        } else {
                            let profanityCheck = TextFilter.shared.validateText(editedName)
                            if !profanityCheck.isValid {
                                validationMessage = profanityCheck.message ?? "부적절한 단어가 포함되어 있어요"
                                hasProfanity = true
                            } else {
                                validationMessage = ""
                                hasProfanity = false
                            }
                        }
                    }
                
                if !editedName.isEmpty {
                    Button(action: {
                        editedName = ""
                    }) {
                        Image(.emptyIcon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 16)
                    .padding(.leading, 8)
                    .opacity(canEdit ? 1 : 0)
                }
            }
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canEdit ? .gray50 : .white100)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canEdit ? .clear : .gray100, lineWidth: 1)
            )
            .onTapGesture {
                if canEdit {
                    focusedField = .name
                }
            }
            
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .typography(.suit14M)
                    .foregroundColor(.error)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private var memoInputField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("메모")
                .typography(.suit16B)
            
            ZStack(alignment: .topLeading) {
                // Placeholder
                if editedMemo.isEmpty {
                    Text("메모를 입력해주세요")
                        .typography(.notosans16R25)
                        .foregroundColor(.gray300)
                        .padding(.horizontal, 19)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
                
                if canEdit {
                    // 편집 가능
                    TextEditor(text: $editedMemo)
                        .typography(.notosans16R25)
                        .foregroundColor(.black100)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .scrollIndicators(.hidden)
                        .focused($focusedField, equals: .memo)
                        .tint(.main500)
                } else {
                    // 편집 불가 : 스크롤만 가능
                    ScrollView {
                        Text(editedMemo.byCharWrapping)
                            .typography(.notosans16R25)
                            .foregroundColor(.black100)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canEdit ? .gray50 : .white100)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canEdit ? .clear : .gray100, lineWidth: 1)
            )
            .onTapGesture {
                if canEdit {
                    focusedField = .memo
                }
            }
        }
    }
    
}

// MARK: - 태그 섹션
extension KeyringEditView {
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("태그")
                .typography(.suit16B)
            
            ChipLayout(verticalSpacing: 8, horizontalSpacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        focusedField = nil
                        showAddTagAlert = true
                    }
                } label: {
                    Image(.plus)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray50)
                        )
                        .padding(.vertical, 1)
                }
                ForEach(availableTags, id: \.self) { tag in
                    ChipView(
                        title: tag,
                        isSelected: editedTags.contains(tag),
                        action: {
                            focusedField = nil
                            if let index = editedTags.firstIndex(of: tag) {
                                editedTags.remove(at: index)
                            } else {
                                editedTags.append(tag)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
