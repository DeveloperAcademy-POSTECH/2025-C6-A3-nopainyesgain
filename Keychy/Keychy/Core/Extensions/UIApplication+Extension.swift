//
//  UIApplication+Extension.swift
//  KeytschPrototype
//
//  Created by seo on 11/16/25.
//

import UIKit

extension UIApplication {
    
    /// 현재 기기의 화면 가로 너비
    static var screenWidth: CGFloat {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 0
    }
    
    /// 현재 기기의 화면 세로 높이
    static var screenHeight: CGFloat {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.height ?? 0
    }
    
    /// 현재 기기의 화면 크기
    static var screenSize: CGSize {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.size ?? .zero
    }
}

// MARK: - 그리드 레이아웃 프레임 계산
// 추가할 비율 등이 있다면 추가하셔서 사용하시면 됩니다
extension UIApplication {
    // MARK: - 2열
    /// 2열 그리드 셀의 너비
    static var twoGridCellWidth: CGFloat {
        gridCellWidth(columns: 2)
    }
    
    /// 2열 그리드 셀의 높이 (비율 3:4)
    static var twoGridCellHeight: CGFloat {
        gridCellHeight(columns: 2)
    }
    
    /// 2열 정사각형 그리드 셀의 크기 (1:1 비율)
    static var twoSquareGridCellSize: CGFloat {
        gridCellWidth(columns: 2)
    }
    
    // MARK: - 3열
    /// 기본 3열 그리드 셀의 너비
    static var threeGridCellWidth: CGFloat {
        gridCellWidth(columns: 3, spacing: 10)
    }
    
    /// 3열 그리드 셀의 높이 (비율 3:4)
    static var threeGridCellHeight: CGFloat {
        gridCellHeight(columns: 3, horizontalPadding: 10)
    }
    
    
    /// 커스텀 컬럼 수에 따른 그리드 셀 너비 계산
    /// - Parameters:
    ///   - columns: 그리드 컬럼 수
    ///   - spacing: 셀 간 간격
    ///   - horizontalPadding: 좌우 여백의 합
    /// - Returns: 계산된 셀의 너비
    static func gridCellWidth(
        columns: Int,
        spacing: CGFloat = Spacing.gap,
        horizontalPadding: CGFloat = Spacing.margin * 2
    ) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        return (screenWidth - horizontalPadding - totalSpacing) / CGFloat(columns)
    }
    
    /// 커스텀 비율에 따른 그리드 셀 높이 계산
    /// - Parameters:
    ///   - columns: 그리드 컬럼 수
    ///   - aspectRatio: 가로:세로 비율 (예: 4/3, 1, 16/9) (기본값 4/3)
    ///   - spacing: 셀 간 간격
    ///   - horizontalPadding: 좌우 여백의 합
    /// - Returns: 계산된 셀의 높이
    static func gridCellHeight(
        columns: Int,
        aspectRatio: CGFloat = 4/3,
        spacing: CGFloat = Spacing.gap,
        horizontalPadding: CGFloat = Spacing.margin * 2
    ) -> CGFloat {
        let width = gridCellWidth(columns: columns, spacing: spacing, horizontalPadding: horizontalPadding)
        return width * aspectRatio
    }
}
