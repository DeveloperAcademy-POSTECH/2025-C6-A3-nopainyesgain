//
//  MKViewModel+CropBoxDrag.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/16/25.
//

import SwiftUI
import PhotosUI

extension ArcylicPhotoVM {
    
    // MARK: - 드래그 시작 시 코너 감지
    func onDragChanged(_ startLocation: CGPoint, _ translation: CGSize) {
        if initialCropArea == nil {
            initialCropArea = cropArea
            draggedCorner = findClosestCorner(point: startLocation)
        }
        
        guard let initial = initialCropArea else { return }
        let imageRect = getDisplayedImageRect()
        
        if let corner = draggedCorner {
            // 코너를 잡았으면 크기 조절
            cropArea = resizeCrop(initial: initial, corner: corner, translation: translation, imageRect: imageRect)
        } else {
            // 중앙을 잡았으면 이동
            cropArea = moveCrop(initial: initial, translation: translation, imageRect: imageRect)
        }
    }
    
    func onDragEnd() {
        initialCropArea = nil
        draggedCorner = nil
    }
    
    // MARK: - 가장 가까운 코너 찾기
    func findClosestCorner(point: CGPoint) -> CropCorner? {
        let threshold: CGFloat = 44
        
        let distances = [
            (CropCorner.topLeft, point.distance(to: CGPoint(x: cropArea.minX, y: cropArea.minY))),
            (CropCorner.topRight, point.distance(to: CGPoint(x: cropArea.maxX, y: cropArea.minY))),
            (CropCorner.bottomLeft, point.distance(to: CGPoint(x: cropArea.minX, y: cropArea.maxY))),
            (CropCorner.bottomRight, point.distance(to: CGPoint(x: cropArea.maxX, y: cropArea.maxY)))
        ]
        
        let closest = distances.min(by: { $0.1 < $1.1 })
        return closest?.1 ?? 0 < threshold ? closest?.0 : nil
    }
    
    // MARK: - 크롭 영역 크기 조절
    func resizeCrop(initial: CGRect, corner: CropCorner, translation: CGSize, imageRect: CGRect) -> CGRect {
        var newRect = initial
        
        switch corner {
        case .topLeft:
            let newX = max(imageRect.minX, min(initial.maxX - minimumCropSize.width, initial.minX + translation.width))
            let newY = max(imageRect.minY, min(initial.maxY - minimumCropSize.height, initial.minY + translation.height))
            newRect.origin.x = newX
            newRect.origin.y = newY
            newRect.size.width = initial.maxX - newX
            newRect.size.height = initial.maxY - newY
            
        case .topRight:
            let newY = max(imageRect.minY, min(initial.maxY - minimumCropSize.height, initial.minY + translation.height))
            let newMaxX = min(imageRect.maxX, max(initial.minX + minimumCropSize.width, initial.maxX + translation.width))
            newRect.origin.y = newY
            newRect.size.width = newMaxX - initial.minX
            newRect.size.height = initial.maxY - newY
            
        case .bottomLeft:
            let newX = max(imageRect.minX, min(initial.maxX - minimumCropSize.width, initial.minX + translation.width))
            let newMaxY = min(imageRect.maxY, max(initial.minY + minimumCropSize.height, initial.maxY + translation.height))
            newRect.origin.x = newX
            newRect.size.width = initial.maxX - newX
            newRect.size.height = newMaxY - initial.minY
            
        case .bottomRight:
            let newMaxX = min(imageRect.maxX, max(initial.minX + minimumCropSize.width, initial.maxX + translation.width))
            let newMaxY = min(imageRect.maxY, max(initial.minY + minimumCropSize.height, initial.maxY + translation.height))
            newRect.size.width = newMaxX - initial.minX
            newRect.size.height = newMaxY - initial.minY
        }
        
        return newRect
    }
    
    // MARK: - 크롭 영역 이동
    func moveCrop(initial: CGRect, translation: CGSize, imageRect: CGRect) -> CGRect {
        var newRect = initial
        newRect.origin.x = initial.minX + translation.width
        newRect.origin.y = initial.minY + translation.height
        
        return constrainToImageRect(newRect, imageRect: imageRect)
    }
    
    // MARK: - 이미지 영역 내로 제한
    func constrainToImageRect(_ rect: CGRect, imageRect: CGRect) -> CGRect {
        var constrained = rect
        
        // 왼쪽 경계
        if constrained.minX < imageRect.minX {
            constrained.origin.x = imageRect.minX
        }
        // 오른쪽 경계
        if constrained.maxX > imageRect.maxX {
            constrained.origin.x = imageRect.maxX - constrained.width
        }
        // 위쪽 경계
        if constrained.minY < imageRect.minY {
            constrained.origin.y = imageRect.minY
        }
        // 아래쪽 경계
        if constrained.maxY > imageRect.maxY {
            constrained.origin.y = imageRect.maxY - constrained.height
        }
        
        return constrained
    }
}
