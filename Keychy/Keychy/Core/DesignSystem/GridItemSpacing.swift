//
//  GridItemSpacing.swift
//  Keychy
//
//  Created by seo on 11/16/25.
//

import UIKit

//MARK: - 그리드 아이템 너비 모음집
/// 2열 그리드 셀의 너비 (UIApplication 접두사 없이 사용 가능)
var twoGridCellWidth: CGFloat {
    UIApplication.gridCellWidth(columns: 2)
}

/// 2열 그리드 셀의 높이 (비율 3:4)
var twoGridCellHeight: CGFloat {
    UIApplication.gridCellHeight(columns: 2)
}

/// 2열 정사각형 그리드 셀의 크기 (1:1 비율)
var twoSquareGridCellSize: CGFloat {
    UIApplication.gridCellWidth(columns: 2)
}

/// 3열 그리드 셀의 너비 (비율 3:4)
var threeGridCellWidth: CGFloat {
    UIApplication.gridCellWidth(columns: 3, spacing: 10)
}

/// 3열 그리드 셀의 높이 (비율 3:4)
var threeGridCellHeight: CGFloat {
    UIApplication.gridCellHeight(columns: 3, aspectRatio: 4/3, spacing: 10)
}

/// 3열 정사각형 그리드 셀의 크기 (1:1 비율)
var threeSquareGridCellSize: CGFloat {
    UIApplication.gridCellWidth(columns: 3, spacing: 10)
}

/// 화면 가로 너비
var screenWidth: CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.screen.bounds.width ?? 0
}

/// 화면 세로 높이
var screenHeight: CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.screen.bounds.height ?? 0
}

/// 화면 크기
var screenSize: CGSize {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.screen.bounds.size ?? .zero
}

