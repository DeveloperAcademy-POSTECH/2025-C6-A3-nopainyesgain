//
//  TemplateInitializer.swift
//  KeytschPrototype
//
//  앱 실행 시 템플릿을 자동으로 Firestore에 업로드 (이미 있으면 스킵)
//

import FirebaseFirestore

/// 앱 실행 시 한 번만 호출하세요
func initializeTemplates() async {
    let templates: [[String: Any]] = [
        [
            "id": "HeartKeyring",
            "templateName": "하트 키링",
            "description": "사랑스러운 하트 모양 키링",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["드로잉형"],
            "price": 100,
            "downloadCount": 234,
            "useCount": 178,
            "isActive": true
        ],
        [
            "id": "SimpleText",
            "templateName": "심플 텍스트",
            "description": "깔끔한 텍스트 스타일 키링",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["텍스트형"],
            "price": 0,
            "downloadCount": 456,
            "useCount": 312,
            "isActive": true
        ],
        [
            "id": "StarKeyring",
            "templateName": "별 키링",
            "description": "반짝이는 별 모양 키링",
            "interactions": ["tap", "swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["드로잉형", "이미지형"],
            "price": 150,
            "downloadCount": 189,
            "useCount": 134,
            "isActive": true
        ],
        [
            "id": "CirclePhoto",
            "templateName": "원형 포토",
            "description": "동그란 원형 사진 키링",
            "interactions": ["swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["이미지형"],
            "price": 50,
            "downloadCount": 321,
            "useCount": 267,
            "isActive": true
        ],
        [
            "id": "MessageCard",
            "templateName": "메시지 카드",
            "description": "특별한 메시지를 담는 카드형 키링",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["텍스트형", "이미지형"],
            "price": 200,
            "downloadCount": 98,
            "useCount": 76,
            "isActive": true
        ],
        [
            "id": "CloudDream",
            "templateName": "구름 드림",
            "description": "몽글몽글 구름 모양 키링",
            "interactions": ["swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["드로잉형"],
            "price": 80,
            "downloadCount": 412,
            "useCount": 358,
            "isActive": true
        ],
        [
            "id": "PolaroidStyle",
            "templateName": "폴라로이드 스타일",
            "description": "빈티지 폴라로이드 느낌의 키링",
            "interactions": ["tap", "swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["이미지형", "텍스트형"],
            "price": 0,
            "downloadCount": 567,
            "useCount": 423,
            "isActive": true
        ],
        [
            "id": "FlowerGarden",
            "templateName": "플라워 가든",
            "description": "예쁜 꽃 패턴 키링",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["드로잉형", "이미지형"],
            "price": 120,
            "downloadCount": 278,
            "useCount": 201,
            "isActive": true
        ],
        [
            "id": "NeonSign",
            "templateName": "네온 사인",
            "description": "형광 네온 스타일 텍스트 키링",
            "interactions": ["swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["텍스트형"],
            "price": 180,
            "downloadCount": 145,
            "useCount": 92,
            "isActive": true
        ],
        [
            "id": "MinimalSquare",
            "templateName": "미니멀 스퀘어",
            "description": "심플한 사각형 키링",
            "interactions": ["tap", "swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["이미지형", "텍스트형"],
            "price": 0,
            "downloadCount": 623,
            "useCount": 511,
            "isActive": true
        ],
        [
            "id": "RainbowDoodle",
            "templateName": "레인보우 두들",
            "description": "알록달록 무지개 낙서 키링",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["드로잉형"],
            "price": 90,
            "downloadCount": 334,
            "useCount": 245,
            "isActive": true
        ],
        [
            "id": "VintageFilm",
            "templateName": "빈티지 필름",
            "description": "필름 카메라 느낌의 레트로 키링",
            "interactions": ["swing"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "previewURL": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "guidingImageURL": "",
            "guidingText": "",
            "tags": ["이미지형"],
            "price": 130,
            "downloadCount": 289,
            "useCount": 198,
            "isActive": true
        ]
    ]
    
    
    // 문서 생성 및 추가 로직
    let db = Firestore.firestore()

    for template in templates {
        guard let id = template["id"] as? String else { continue }

        var data = template
        data.removeValue(forKey: "id")

        do {
            let doc = try await db.collection("Template").document(id).getDocument()

            // 신규 문서인 경우에만 createdAt 추가
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }

            // merge: true로 기존 필드 유지 + 새 필드 추가
            try await db.collection("Template").document(id).setData(data, merge: true)
        } catch {
            print("Template \(id) 오류: \(error)")
        }
    }
}
