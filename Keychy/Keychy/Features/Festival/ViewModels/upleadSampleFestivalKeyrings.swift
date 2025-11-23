//
//  upleadSampleFestivalKeyrings.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import Foundation
import FirebaseFirestore

/// ShowcaseFestivalKeyring 컬렉션에 20개의 샘플 데이터 업로드
/// 기존 데이터를 모두 삭제 후 새로 업로드
func uploadSampleFestivalKeyrings() async {
    let db = Firestore.firestore()
    let collection = db.collection("ShowcaseFestivalKeyring")

    do {
        // 1. 기존 데이터 모두 삭제
        print("🗑️ Deleting existing festival keyrings...")
        let existingDocs = try await collection.getDocuments()

        for document in existingDocs.documents {
            try await document.reference.delete()
            print("🗑️ Deleted document: \(document.documentID)")
        }
        print("✅ Deleted \(existingDocs.documents.count) existing documents")

        // 2. 0~99 중에서 20개의 고유한 gridIndex 생성
        var gridIndices = Array(0...99)
        gridIndices.shuffle()
        let selectedIndices = Array(gridIndices.prefix(20))

        let sampleBodyImageURL = "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Keyrings%2FBodyImages%2F1SbgBiUT1ucH4LOIhp73KEgk6q32%2F02194AA5-B590-4E3A-BF4C-798EA0074130.png?alt=media&token=ef2414b9-d218-4870-a52b-3309b183def1"

        // 3. 새 데이터 업로드
        print("📤 Uploading new festival keyrings...")
        for gridIndex in selectedIndices {
            let data: [String: Any] = [
                "bodyImageURL": sampleBodyImageURL,
                "gridIndex": gridIndex,
                "isEditing": false,
                "keyringID": "none",
                "memo": "none",
                "particleid": "none",
                "soundId": "none",
                "votes": 0
            ]

            try await collection.addDocument(data: data)
            print("✅ Uploaded festival keyring with gridIndex: \(gridIndex)")
        }

        print("🎉 Successfully uploaded 20 festival keyrings")

    } catch {
        print("❌ Failed to upload festival keyrings: \(error.localizedDescription)")
    }
}
