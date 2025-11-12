//
//  BundleEditView.swift
//  Keychy
//
//  Created by 김서현 on 11/10/25.
//

import SwiftUI
import NukeUI

struct BundleEditView: View {
    @Bindable var router: NavigationRouter<HomeRoute>
    @State var viewModel: CollectionViewModel
    
    @State private var selectedCategory: String = ""
    @State private var selectedKeyringPosition: Int = 0
    @State private var newSelectedBackground: BackgroundViewData?
    // 선택한 카라비너 -> 알럿창 확인 눌러야 뉴선택 카라비너로 바뀜
    @State private var selectCarabiner: CarabinerViewData?
    @State private var newSelectedCarabiner: CarabinerViewData?
    
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    @State private var showChangeCarabinerAlert: Bool = false
    @State private var sheetHeight: CGFloat = 360
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            //TODO: 임시로 올려둔 배경화면과 카라비너입니다.
            if let bg = newSelectedBackground {
                LazyImage(url: URL(string: bg.background.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            if let cb = newSelectedCarabiner {
                VStack {
                    LazyImage(url: URL(string: cb.carabiner.carabinerImage[0])) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    Spacer()
                }
            }
            // 배경 시트
            if showBackgroundSheet {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: selectBackgroundSheet
                    )
                }
            }
            
            // 카라비너 시트
            if showCarabinerSheet {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        editBackgroundButton
                        editCarabinerButton
                        Spacer()
                    }
                    .padding(.leading, 18)
                    BundleItemCustomSheet(
                        sheetHeight: $sheetHeight,
                        content: selectCarabinerSheet
                    )
                }
            }
            
            if !showCarabinerSheet && !showBackgroundSheet {
                HStack(spacing: 8) {
                    editBackgroundButton
                    editCarabinerButton
                    Spacer()
                }
                .padding(.leading, 18)
            }
            
            if showChangeCarabinerAlert {
                Color.black20
                    .ignoresSafeArea()
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showChangeCarabinerAlert = false
                        }
                    }
                VStack {
                    Spacer()
                    CarabinerChangePopup(
                        title: "카라비너를 변경하시겠어요?",
                        message: "새 카라비너로 변경하면\n현재 뭉치에 걸린 키링들이 모두 해제돼요.",
                        onCancel: {
                            selectCarabiner = nil
                            showChangeCarabinerAlert = false
                        },
                        onConfirm: {
                            newSelectedCarabiner = selectCarabiner
                            showChangeCarabinerAlert = false
                        }
                    )
                    .padding(.horizontal, 51)
                    Spacer()
                }
            }
        }
        .toolbar {
            backButton
            editCompleteButton
        }
        .navigationBarBackButtonHidden()
        .task {
            viewModel.fetchAllBackgrounds { _ in
                if let selectedBundle = viewModel.selectedBundle {
                    // selectedBackground는 ID(String)이므로 BackgroundViewData를 찾아야 함
                    newSelectedBackground = viewModel.backgroundViewData.first { bgData in
                        bgData.background.id == selectedBundle.selectedBackground
                    }
                }
                viewModel.fetchAllCarabiners { _ in
                    if let selectedBundle = viewModel.selectedBundle {
                        // selectedCarabiner도 동일하게 ID로 CarabinerViewData를 찾음
                        newSelectedCarabiner = viewModel.carabinerViewData.first { cbData in
                            cbData.carabiner.id == selectedBundle.selectedCarabiner
                        }
                    }
                }
            }
        }
        .onAppear {
            // 현재 선택된 번들의 배경과 카라비너를 초기값으로 설정
            
        }
        .ignoresSafeArea()
        .onChange(of: showBackgroundSheet) { oldValue, newValue in
            if newValue {
                showCarabinerSheet = false
            }
        }
        .onChange(of: showCarabinerSheet) { oldValue, newValue in
            if newValue {
                showBackgroundSheet = false
            }
        }
    }
}

// MARK: - 툴바
extension BundleEditView {
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(.lessThan)
                    .resizable()
            }
            .frame(width: 44, height: 44)
            .buttonStyle(.glass)
        }
    }
    private var editCompleteButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                //action
            } label: {
                Text("완료")
            }
        }
    }
}

//MARK: - 하단 버튼
extension BundleEditView {
    private var editBackgroundButton: some View {
        Button {
            // 배경 시트 열기
            showBackgroundSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showBackgroundSheet ? .backgroundIconWhite100 : .backgroundIconGray600)
                    .resizable()
                    .scaledToFit()
                Text("배경")
                    .typography(.suit9SB)
                    .foregroundStyle(showBackgroundSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showBackgroundSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var editCarabinerButton: some View {
        Button {
            // 카라비너 시트 열기
            showCarabinerSheet = true
        } label: {
            VStack(spacing: 0) {
                Image(showCarabinerSheet ? .carabinerIconWhite100 : .carabinerIconGray600)
                    .resizable()
                    .scaledToFit()
                Text("카라비너")
                    .typography(.suit9SB)
                    .foregroundStyle(showCarabinerSheet ? .white100 : .gray600)
            }
            .frame(width: 46, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14.38)
                    .fill(showCarabinerSheet ? .main500 : .white100)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 시트 뷰
extension BundleEditView {
    private var selectBackgroundSheet: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.backgroundViewData) { bg in
                SelectBackgroundGridItem(
                    background: bg, isSelected: newSelectedBackground == bg
                )
                .onTapGesture {
                    newSelectedBackground = bg
                    
                    if !bg.isOwned && bg.background.isFree {
                        Task {
                            await viewModel.addBackgroundToUser(backgroundName: bg.background.backgroundImage, userManager: UserManager.shared)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
    
    private var selectCarabinerSheet: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.carabinerViewData) { cb in
                SelectCarabinerGridItem(isSelected: newSelectedCarabiner == cb, carabiner: cb)
                    .onTapGesture {
                        selectCarabiner = cb
                        showChangeCarabinerAlert = true
                        if !cb.isOwned && cb.carabiner.isFree {
                            Task {
                                // 유저 carabiner 배열에 추가
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}
