//
//  uploadSampleFestivalKeyrings.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import Foundation
import FirebaseFirestore

/// ShowcaseFestivalKeyring 컬렉션에 144개의 빈 문서 생성 (gridIndex 0~143)
/// 기존 데이터를 모두 삭제 후 새로 생성
func uploadSampleFestivalKeyrings() async {
    let db = Firestore.firestore()
    let collection = db.collection("ShowcaseFestivalKeyring")

    do {
        // 1. 기존 데이터 모두 삭제
        print("🗑️ Deleting existing festival keyrings...")
        let existingDocs = try await collection.getDocuments()

        for document in existingDocs.documents {
            try await document.reference.delete()
        }
        print("✅ Deleted \(existingDocs.documents.count) existing documents")

        // 2. 144개의 빈 문서 생성 (gridIndex 0~143)
        print("📤 Creating 144 empty festival keyring documents...")
        for gridIndex in 0..<144 {
            let data: [String: Any] = [
                "name": "",
                "authorId": "",
                "bodyImageURL": "",
                "gridIndex": gridIndex,
                "isEditing": false,
                "editingUserNickname": "",
                "keyringId": "none",
                "memo": "",
                "particleId": "none",
                "soundId": "none",
                "votes": 0
            ]

            try await collection.addDocument(data: data)
        }

        print("🎉 Successfully created 144 empty festival keyring documents")

    } catch {
        print("❌ Failed to create festival keyrings: \(error.localizedDescription)")
    }
}
