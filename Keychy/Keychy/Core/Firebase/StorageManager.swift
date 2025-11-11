//
//  StorageManager.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import FirebaseStorage

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
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return data
    }
    
    // MARK: - URL에서 이미지 가져오기
    func getImage(path: String) async throws -> UIImage {
        // 캐시 확인
        if let cachedImage = getCachedImage(for: path) {
            return cachedImage
        }
        
        let data = try await getData(path: path)
        
        guard let image = UIImage(data: data) else {
            print("이미지 변환 실패: \(path)")
            throw URLError(.badServerResponse)
        }
        
        // 캐시에 저장
        setCachedImage(image, for: path)
        
        return image
    }
    
    func getMultipleImages(paths: [String]) async throws -> [String: UIImage] {
        
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

    // MARK: - 업로드

    /// 이미지 업로드 (PNG)
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "StorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "PNG 변환 실패"])
        }

        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    /// 오디오 업로드 (M4A)
    func uploadAudio(_ audioData: Data, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(audioData)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    /// 범용 데이터 업로드
    func uploadData(_ data: Data, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child(path)
        _ = try await storageRef.putDataAsync(data)
        let downloadURL = try await storageRef.downloadURL()

        return downloadURL.absoluteString
    }

    // MARK: - 삭제

    /// 특정 파일 삭제
    func deleteFile(path: String) async throws {
        let storageRef = Storage.storage().reference().child(path)
        try await storageRef.delete()
    }

    /// 사용자 폴더 전체 삭제 (Keyrings/BodyImages/{uid}/, Keyrings/CustomSounds/{uid}/)
    func deleteUserFolder(uid: String) async throws {
        let bodyImagesPath = "Keyrings/BodyImages/\(uid)"
        let customSoundsPath = "Keyrings/CustomSounds/\(uid)"

        try await deleteFolder(path: bodyImagesPath)
        try await deleteFolder(path: customSoundsPath)
    }

    /// 폴더 삭제 (모든 하위 파일 삭제)
    private func deleteFolder(path: String) async throws {
        let storageRef = Storage.storage().reference().child(path)

        do {
            let result = try await storageRef.listAll()

            for item in result.items {
                try await item.delete()
            }

            for prefix in result.prefixes {
                try await deleteFolder(path: prefix.fullPath)
            }

            print("Storage 폴더 삭제 완료: \(path)")
        } catch {
            if (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                print("Storage 폴더 없음 (이미 삭제됨): \(path)")
            } else {
                throw error
            }
        }
    }

}
