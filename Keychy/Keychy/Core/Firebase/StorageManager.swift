//
//  StorageManager.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI

@Observable
class StorageManager {
    
    static let shared = StorageManager()
    
    private var imageCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.keychy.storageCache", attributes: .concurrent)
    
    private init() {}
    
    func getData(path: String) async throws -> Data {
        guard let url = URL(string: path) else {
            print("잘못된 URL: \(path)")
            throw URLError(.badURL)
        }
        
        print("데이터 다운로드 시작: \(url.lastPathComponent)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        print("데이터 다운로드 완료: \(data.count) bytes")
        return data
    }
    
    // MARK: - URL에서 이미지 가져오기
    func getImage(path: String) async throws -> UIImage {
        // 캐시 확인
        if let cachedImage = getCachedImage(for: path) {
            print("캐시에서 이미지 로드: \(path)")
            return cachedImage
        }
        
        let data = try await getData(path: path)
        
        guard let image = UIImage(data: data) else {
            print("이미지 변환 실패: \(path)")
            throw URLError(.badServerResponse)
        }
        
        // 캐시에 저장
        setCachedImage(image, for: path)
        print("이미지 다운로드 및 캐싱 완료")
        
        return image
    }
    
    func getMultipleImages(paths: [String]) async throws -> [String: UIImage] {
        print("\(paths.count)개 이미지 일괄 다운로드 시작")
        
        return try await withThrowingTaskGroup(of: (String, UIImage).self) { group in
            var images: [String: UIImage] = [:]
            
            for path in paths {
                group.addTask {
                    let image = try await self.getImage(path: path)
                    return (path, image)
                }
            }
            
            for try await (path, image) in group {
                images[path] = image
            }
            
            print("일괄 다운로드 완료: \(images.count)/\(paths.count)개")
            return images
        }
    }
    
    // MARK: - 캐시 관리 (수정 예정)
    private func getCachedImage(for path: String) -> UIImage? {
        cacheQueue.sync {
            return imageCache[path]
        }
    }
    
    private func setCachedImage(_ image: UIImage, for path: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[path] = image
        }
    }
    
    // 특정 이미지 캐시 삭제
    func removeCachedImage(for path: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeValue(forKey: path)
            print("캐시 삭제: \(path)")
        }
    }
    
    // 전체 캐시 삭제
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
            print("이미지 캐시 전체 삭제")
        }
    }
    
}
