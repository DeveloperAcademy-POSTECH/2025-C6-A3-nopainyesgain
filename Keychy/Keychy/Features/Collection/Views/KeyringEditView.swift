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
    
    @FocusState private var focusedField: Field?
    
    let keyring: Keyring
    
    var userManager: UserManager = UserManager.shared

    var availableTags: [String] {
        userManager.currentUser?.tags ?? []
    }
    
    private var isCompleteEnabled: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var canEdit: Bool {
        //keyring.isEditable
        guard let currentUserId = UserDefaults.standard.string(forKey: "userUID") else {
            return false
        }
        return keyring.authorId == currentUserId
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
            VStack {
                keyringSection
                
                ScrollView {
                    infoInputSection
                    
                    tagSection
                }
                .scrollIndicators(.hidden)
                
                Spacer()
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
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(200)
            }
        }
        .navigationTitle("정보 수정")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var completeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isCompleteEnabled {
                Button(role: .confirm, action: {
                    viewModel.updateKeyring(
                        keyring: keyring,
                        name: editedName,
                        memo: editedMemo,
                        tags: editedTags
                    ) { success in
                        if success {
                            router.reset()
                        }
                    }
                }) {
                    Image("recCheck")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.white100)

                }
            }
            else {
                Button(action: {
                    // disabled
                }) {
                    Image("recCheck")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.gray300)

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
                    scene: createMiniScene(keyring: keyring)
                )
                if isLoading {
                    Color.black20
                        .overlay {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(1.2)
                                
                                Text("키링을 가져오는 중...")
                                    .typography(.suit12M)
                                    .foregroundColor(.white)
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
            zoomScale: 2.0,
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
                    .typography(.pretendard16M)
                    .foregroundColor(.black100)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .name)
                    .disabled(!canEdit)
                    .onChange(of: editedName) { _, newValue in
                        let regexString = "[^가-힣\\u3131-\\u314E\\u314F-\\u3163a-zA-Z0-9\\s]+"
                        var sanitized = newValue.replacingOccurrences(
                            of: regexString,
                            with: "",
                            options: .regularExpression
                        )
                        
                        if sanitized.count > 9 {
                            sanitized = String(sanitized.prefix(9))
                        }
                        
                        if sanitized != editedName {
                            editedName = sanitized
                        }
                    }
                
                if !editedName.isEmpty {
                    Button(action: {
                        editedName = ""
                    }) {
                        Image("EmptyIcon")
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
                        .typography(.suit16M25)
                        .foregroundColor(.gray300)
                        .padding(.horizontal, 19)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $editedMemo)
                    .typography(.pretendard16M)
                    .foregroundColor(.black100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .scrollIndicators(.hidden)
                    .focused($focusedField, equals: .memo)
                    .disabled(!canEdit)
            }
            .frame(height: 135)
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
