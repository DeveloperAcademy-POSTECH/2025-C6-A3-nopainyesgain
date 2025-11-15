//
//  SelectionGridSheet.swift
//  Keychy
//
//  Created by 김서현 on 11/14/25.
//

import SwiftUI

/// 제네릭 선택 그리드 시트 컴포넌트
struct SelectionGridSheet<Item: Identifiable & Equatable, GridItemView: View>: View {
    // MARK: - Properties
    
    /// 표시할 아이템 배열
    let items: [Item]
    /// 현재 선택된 아이템 (nil 가능)
    let selectedItem: Item?
    /// 화면 너비 크기
    let widthSize: CGFloat
    /// 아이템 탭 시 실행될 클로저
    let onItemTap: (Item) -> Void
    /// 각 그리드 아이템을 만드는 ViewBuilder 클로저
    let gridItemViewBuilder: (Item, Bool, CGFloat) -> GridItemView
    
    /// 3열 그리드 컬럼 설정
    private let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    /// - Parameters:
    ///   - items: 표시할 아이템 배열
    ///   - selectedItem: 현재 선택된 아이템 (nil 가능)
    ///   - widthSize: 화면 너비 크기
    ///   - onItemTap: 아이템 탭 시 실행될 클로저
    ///   - gridItemView: 각 그리드 아이템을 만드는 ViewBuilder
    init(
        items: [Item],
        selectedItem: Item?,
        widthSize: CGFloat,
        onItemTap: @escaping (Item) -> Void,
        @ViewBuilder gridItemView: @escaping (Item, Bool, CGFloat) -> GridItemView
    ) {
        self.items = items
        self.selectedItem = selectedItem
        self.widthSize = widthSize
        self.onItemTap = onItemTap
        self.gridItemViewBuilder = gridItemView
    }
    
    // MARK: - Body
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(items) { item in
                gridItemViewBuilder(
                    item,
                    selectedItem == item,
                    widthSize
                )
                .onTapGesture {
                    onItemTap(item)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
}
