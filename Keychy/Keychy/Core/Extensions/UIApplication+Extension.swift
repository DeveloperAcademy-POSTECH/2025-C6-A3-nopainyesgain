//
//  UIApplication+Extension.swift
//  KeytschPrototype
//
//  Created by seo on 11/16/25.
//

import UIKit

// MARK: - Grid Layout Helpers
extension UIApplication {
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
    ///   - aspectRatio: 가로:세로 비율 (예: 4/3, 1, 16/9)
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
