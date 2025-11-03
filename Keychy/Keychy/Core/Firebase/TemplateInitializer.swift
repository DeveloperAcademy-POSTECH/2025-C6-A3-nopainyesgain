//
//  DataInitializer.swift
//  KeytschPrototype
//
//  앱 실행 시 데이터를 자동으로 Firestore에 업로드 (이미 있으면 스킵)
//

import FirebaseFirestore

/// 앱 실행 시 한 번만 호출하세요
func initializeData() async {
    await initializeTemplates()
    await initializeBackgrounds()
    await initializeCarabiners()
    await initializeParticles()
    await initializeSounds()
}

// MARK: - Template Initialization
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
    
    let db = Firestore.firestore()
    
    for template in templates {
        guard let id = template["id"] as? String else { continue }
        
        var data = template
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Template").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Template").document(id).setData(data, merge: true)
        } catch {
            print("Template \(id) 오류: \(error)")
        }
    }
}

// MARK: - Background Initialization
func initializeBackgrounds() async {
    let backgrounds: [[String: Any]] = [
        [
            "id": "PastelPink",
            "backgroundName": "파스텔 핑크",
            "description": "부드럽고 따뜻한 핑크 배경",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 80,
            "downloadCount": 723,
            "useCount": 645
        ],
        [
            "id": "NeonCity",
            "backgroundName": "네온 도시",
            "description": "화려한 도시의 네온 불빛",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 150,
            "downloadCount": 567,
            "useCount": 489
        ],
        [
            "id": "MinimalWhite",
            "backgroundName": "미니멀 화이트",
            "description": "깔끔하고 심플한 화이트",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 0,
            "downloadCount": 891,
            "useCount": 756
        ],
        [
            "id": "DarkMoon",
            "backgroundName": "다크 문",
            "description": "신비로운 달빛의 어둠",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 0,
            "downloadCount": 512,
            "useCount": 423
        ]
    ]
    
    let db = Firestore.firestore()
    
    for background in backgrounds {
        guard let id = background["id"] as? String else { continue }
        
        var data = background
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Background").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Background").document(id).setData(data, merge: true)
        } catch {
            print("Background \(id) 오류: \(error)")
        }
    }
}

// MARK: - Carabiner Initialization
func initializeCarabiners() async {
    let carabiners: [[String: Any]] = [
        [
            "id": "BasicSilver",
            "carabinerName": "베이직 실버",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "심플한 실버 카라비너",
            "maxKeyringCount": 5,
            "tags": ["심플"],
            "price": 0,
            "downloadCount": 1234,
            "useCount": 1023,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.4, 0.6],
            "keyringYPosition": [0.3, 0.4, 0.4, 0.5, 0.5]
        ],
        [
            "id": "GoldLuxury",
            "carabinerName": "골드 럭셔리",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "고급스러운 골드 카라비너",
            "maxKeyringCount": 7,
            "tags": ["심플"],
            "price": 200,
            "downloadCount": 567,
            "useCount": 478,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.2, 0.8, 0.4, 0.6],
            "keyringYPosition": [0.35, 0.45, 0.45, 0.55, 0.55, 0.65, 0.65]
        ],
        [
            "id": "RainbowColor",
            "carabinerName": "레인보우 컬러",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "알록달록 무지개 카라비너",
            "maxKeyringCount": 6,
            "tags": ["귀여움"],
            "price": 150,
            "downloadCount": 789,
            "useCount": 645,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.2, 0.8, 0.5],
            "keyringYPosition": [0.32, 0.42, 0.42, 0.52, 0.52, 0.62]
        ],
        [
            "id": "HeartShape",
            "carabinerName": "하트 모양",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "사랑스러운 하트 카라비너",
            "maxKeyringCount": 4,
            "tags": ["귀여움"],
            "price": 100,
            "downloadCount": 923,
            "useCount": 812,
            "keyringXPosition": [0.1, 0.8, 0.2, 0.8],
            "keyringYPosition": [0.35, 0.2, 0.8, 0.8]
        ],
        [
            "id": "StarDesign",
            "carabinerName": "별 디자인",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "반짝이는 별 모양 카라비너",
            "maxKeyringCount": 5,
            "tags": ["귀여움"],
            "price": 120,
            "downloadCount": 634,
            "useCount": 556,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.4, 0.6],
            "keyringYPosition": [0.3, 0.4, 0.4, 0.5, 0.5]
        ],
        [
            "id": "MiniSize",
            "carabinerName": "미니 사이즈",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "작고 귀여운 미니 카라비너",
            "maxKeyringCount": 3,
            "tags": ["귀여움"],
            "price": 0,
            "downloadCount": 1456,
            "useCount": 1234,
            "keyringXPosition": [0.5, 0.3, 0.7],
            "keyringYPosition": [0.25, 0.35, 0.35]
        ],
        [
            "id": "LargeCapacity",
            "carabinerName": "라지 캐퍼시티",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "많이 걸 수 있는 대용량 카라비너",
            "maxKeyringCount": 10,
            "tags": ["심플"],
            "price": 250,
            "downloadCount": 445,
            "useCount": 367,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.2, 0.8, 0.4, 0.6, 0.3, 0.7, 0.5],
            "keyringYPosition": [0.4, 0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9]
        ],
        [
            "id": "PastelPink",
            "carabinerName": "파스텔 핑크",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "부드러운 핑크 카라비너",
            "maxKeyringCount": 5,
            "tags": ["귀여움"],
            "price": 80,
            "downloadCount": 867,
            "useCount": 723,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.4, 0.6],
            "keyringYPosition": [0.3, 0.4, 0.4, 0.5, 0.5]
        ],
        [
            "id": "BlackMatte",
            "carabinerName": "블랙 매트",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "세련된 블랙 매트 카라비너",
            "maxKeyringCount": 6,
            "tags": ["심플"],
            "price": 0,
            "downloadCount": 1089,
            "useCount": 934,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.2, 0.8, 0.5],
            "keyringYPosition": [0.33, 0.4, 0.4, 0.5, 0.5, 0.6]
        ],
        [
            "id": "ClearTransparent",
            "carabinerName": "클리어 투명",
            "carabinerImage": ["https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24"],
            "description": "투명한 아크릴 카라비너",
            "maxKeyringCount": 5,
            "tags": ["심플"],
            "price": 130,
            "downloadCount": 723,
            "useCount": 612,
            "keyringXPosition": [0.5, 0.3, 0.7, 0.4, 0.6],
            "keyringYPosition": [0.3, 0.4, 0.4, 0.5, 0.5]
        ]
    ]
    
    let db = Firestore.firestore()
    
    for carabiner in carabiners {
        guard let id = carabiner["id"] as? String else { continue }
        
        var data = carabiner
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Carabiner").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Carabiner").document(id).setData(data, merge: true)
        } catch {
            print("Carabiner \(id) 오류: \(error)")
        }
    }
}

// MARK: - Particle Initialization
func initializeParticles() async {
    let particles: [[String: Any]] = [
        [
            "id": "Sparkle",
            "particleName": "반짝반짝",
            "description": "반짝이는 별 파티클",
            "particleData": "sparkle_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 0,
            "downloadCount": 1567,
            "useCount": 1345
        ],
        [
            "id": "HeartBurst",
            "particleName": "하트 버스트",
            "description": "하트가 터지는 이펙트",
            "particleData": "heart_burst_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 100,
            "downloadCount": 934,
            "useCount": 812
        ],
        [
            "id": "Confetti",
            "particleName": "컨페티",
            "description": "알록달록 종이 조각",
            "particleData": "confetti_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 80,
            "downloadCount": 1123,
            "useCount": 978
        ],
        [
            "id": "Fireworks",
            "particleName": "불꽃놀이",
            "description": "화려한 불꽃 효과",
            "particleData": "fireworks_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 150,
            "downloadCount": 845,
            "useCount": 723
        ],
        [
            "id": "BubbleFloat",
            "particleName": "비눗방울",
            "description": "둥둥 떠다니는 비눗방울",
            "particleData": "bubble_float_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 70,
            "downloadCount": 1234,
            "useCount": 1067
        ],
        [
            "id": "MagicDust",
            "particleName": "마법 가루",
            "description": "신비로운 마법 가루 효과",
            "particleData": "magic_dust_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 0,
            "downloadCount": 1478,
            "useCount": 1289
        ],
        [
            "id": "Galaxy",
            "particleName": "은하수",
            "description": "우주 은하수 효과",
            "particleData": "galaxy_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 180,
            "downloadCount": 667,
            "useCount": 556
        ]
    ]
    
    let db = Firestore.firestore()
    
    for particle in particles {
        guard let id = particle["id"] as? String else { continue }
        
        var data = particle
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Particle").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Particle").document(id).setData(data, merge: true)
        } catch {
            print("Particle \(id) 오류: \(error)")
        }
    }
}

// MARK: - Sound Initialization
func initializeSounds() async {
    let sounds: [[String: Any]] = [
        [
            "id": "BellRing",
            "soundName": "종소리",
            "description": "맑은 종소리",
            "soundData": "bell_ring_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 0,
            "downloadCount": 2134,
            "useCount": 1890
        ],
        [
            "id": "PianoNote",
            "soundName": "피아노 음",
            "description": "부드러운 피아노 소리",
            "soundData": "piano_note_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 80,
            "downloadCount": 1678,
            "useCount": 1456
        ],
        [
            "id": "Chime",
            "soundName": "차임벨",
            "description": "영롱한 차임벨 소리",
            "soundData": "chime_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 100,
            "downloadCount": 1345,
            "useCount": 1178
        ],
        [
            "id": "GuitarStrum",
            "soundName": "기타 스트럼",
            "description": "경쾌한 기타 소리",
            "soundData": "guitar_strum_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플"],
            "price": 90,
            "downloadCount": 1123,
            "useCount": 967
        ],
        [
            "id": "Xylophone",
            "soundName": "실로폰",
            "description": "톡톡 실로폰 소리",
            "soundData": "xylophone_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 70,
            "downloadCount": 1456,
            "useCount": 1267
        ],
        [
            "id": "MusicBox",
            "soundName": "오르골",
            "description": "감미로운 오르골 소리",
            "soundData": "music_box_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 150,
            "downloadCount": 1678,
            "useCount": 1489
        ],
        [
            "id": "HeartBeat",
            "soundName": "심장박동",
            "description": "두근두근 심장 소리",
            "soundData": "heart_beat_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움"],
            "price": 110,
            "downloadCount": 989,
            "useCount": 856
        ]
    ]
    
    let db = Firestore.firestore()
    
    for sound in sounds {
        guard let id = sound["id"] as? String else { continue }
        
        var data = sound
        data.removeValue(forKey: "id")
        
        do {
            let doc = try await db.collection("Sound").document(id).getDocument()
            
            if !doc.exists {
                data["createdAt"] = Timestamp(date: Date())
            }
            
            try await db.collection("Sound").document(id).setData(data, merge: true)
        } catch {
            print("Sound \(id) 오류: \(error)")
        }
    }
}
