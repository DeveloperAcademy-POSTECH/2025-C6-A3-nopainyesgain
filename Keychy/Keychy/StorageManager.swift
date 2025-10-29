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
    

    
    // TODO: 캐시 관리

    
}
