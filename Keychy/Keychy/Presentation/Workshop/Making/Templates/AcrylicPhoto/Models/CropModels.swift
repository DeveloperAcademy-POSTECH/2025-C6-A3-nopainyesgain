//
//  CropModels.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/16/25.
//
//

import CoreGraphics

// MARK: - CropCorner Enum
enum CropCorner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

// MARK: - CGPoint Extension
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
