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
    @State private var newSelectedCarabiner: CarabinerViewData?
    
    @State private var showBackgroundSheet: Bool = false
    @State private var showCarabinerSheet: Bool = false
    @State private var sheetHeight: CGFloat = 360
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let bg = viewModel.selectedBackground {
                LazyImage(url: URL(string: bg.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            // 배경 시트
            if showBackgroundSheet {
                VStack(spacing: 10) {
                    HStack(spacing: 20) {
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
        }
        .toolbar {
            backButton
            editCompleteButton
        }
        .task {
            viewModel.fetchAllBackgrounds { success in
                if !success {
                    print("배경 데이터 로드 실패")
                }
            }
            viewModel.fetchAllCarabiners { success in
                print("카라비너 목록 로드: \(success), 개수: \(viewModel.carabinerViewData.count)")
            }
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
            VStack {
                Image(.backgroundIcon)
                Text("배경")
                    
            }
        }
        .buttonStyle(.glass)
        .frame(width: 48, height: 48)
    }
    
    private var editCarabinerButton: some View {
        Button {
            // 카라비너 시트 열기
            showCarabinerSheet = true
        } label: {
            Image(.carabinerIcon)
        }
        .frame(width: 48, height: 48)
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
        .padding(.vertical, 20)
    }
    
    private var selectCarabinerSheet: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.carabinerViewData) { cb in
                CarabinerItemTile(isSelected: newSelectedCarabiner == cb, carabiner: cb)
                    .onTapGesture {
                        newSelectedCarabiner = cb
                        
                        if !cb.isOwned && cb.carabiner.isFree {
                            Task {
                                // 유저 carabiner 배열에 추가
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}
