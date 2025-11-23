//
//  upleadSampleFestivalKeyrings.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import Foundation
import FirebaseFirestore

/// ShowcaseFestivalKeyring 컬렉션에 400개의 빈 문서 생성 (gridIndex 0~399)
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

        // 2. 400개의 빈 문서 생성 (gridIndex 0~399)
        print("📤 Creating 400 empty festival keyring documents...")
        for gridIndex in 0..<400 {
            let data: [String: Any] = [
                "authorId": "",
                "bodyImageURL": "",
                "gridIndex": gridIndex,
                "isEditing": false,
                "keyringId": "",
                "memo": "",
                "particleid": "",
                "soundId": "",
                "votes": 0
            ]

            try await collection.addDocument(data: data)
        }

        print("🎉 Successfully created 400 empty festival keyring documents")

    } catch {
        print("❌ Failed to create festival keyrings: \(error.localizedDescription)")
    }
}
