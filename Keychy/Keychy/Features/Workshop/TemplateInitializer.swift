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
            "id": "SkyBlue",
            "backgroundName": "하늘 파랑",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#파랑"],
            "price": 0,
            "downloadCount": 534,
            "useCount": 412
        ],
        [
            "id": "SunsetOrange",
            "backgroundName": "석양 오렌지",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#오렌지"],
            "price": 50,
            "downloadCount": 421,
            "useCount": 356
        ],
        [
            "id": "ForestGreen",
            "backgroundName": "숲속 초록",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#초록"],
            "price": 0,
            "downloadCount": 389,
            "useCount": 298
        ],
        [
            "id": "StarryNight",
            "backgroundName": "별이 빛나는 밤",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#밤하늘"],
            "price": 100,
            "downloadCount": 612,
            "useCount": 534
        ],
        [
            "id": "PastelPink",
            "backgroundName": "파스텔 핑크",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움", "#핑크"],
            "price": 80,
            "downloadCount": 723,
            "useCount": 645
        ],
        [
            "id": "OceanWave",
            "backgroundName": "파도 물결",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#바다"],
            "price": 0,
            "downloadCount": 456,
            "useCount": 378
        ],
        [
            "id": "AutumnLeaves",
            "backgroundName": "가을 낙엽",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#가을"],
            "price": 120,
            "downloadCount": 334,
            "useCount": 267
        ],
        [
            "id": "NeonCity",
            "backgroundName": "네온 도시",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["도시", "#네온"],
            "price": 150,
            "downloadCount": 567,
            "useCount": 489
        ],
        [
            "id": "MinimalWhite",
            "backgroundName": "미니멀 화이트",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["심플", "#화이트"],
            "price": 0,
            "downloadCount": 891,
            "useCount": 756
        ],
        [
            "id": "GalaxyPurple",
            "backgroundName": "은하수 퍼플",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["우주", "#퍼플"],
            "price": 180,
            "downloadCount": 445,
            "useCount": 378
        ],
        [
            "id": "CherryBlossom",
            "backgroundName": "벚꽃 봄날",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#봄"],
            "price": 90,
            "downloadCount": 678,
            "useCount": 589
        ],
        [
            "id": "DarkMoon",
            "backgroundName": "다크 문",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["밤", "#다크"],
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
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "심플한 실버 카라비너",
            "maxKeyringCount": 5,
            "tags": ["심플", "#실버"],
            "price": 0,
            "downloadCount": 1234,
            "useCount": 1023,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.3
        ],
        [
            "id": "GoldLuxury",
            "carabinerName": "골드 럭셔리",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "고급스러운 골드 카라비너",
            "maxKeyringCount": 7,
            "tags": ["럭셔리", "#골드"],
            "price": 200,
            "downloadCount": 567,
            "useCount": 478,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.35
        ],
        [
            "id": "RainbowColor",
            "carabinerName": "레인보우 컬러",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "알록달록 무지개 카라비너",
            "maxKeyringCount": 6,
            "tags": ["귀여움", "#레인보우"],
            "price": 150,
            "downloadCount": 789,
            "useCount": 645,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.32
        ],
        [
            "id": "HeartShape",
            "carabinerName": "하트 모양",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "사랑스러운 하트 카라비너",
            "maxKeyringCount": 4,
            "tags": ["귀여움", "#하트"],
            "price": 100,
            "downloadCount": 923,
            "useCount": 812,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.28
        ],
        [
            "id": "StarDesign",
            "carabinerName": "별 디자인",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "반짝이는 별 모양 카라비너",
            "maxKeyringCount": 5,
            "tags": ["귀여움", "#별"],
            "price": 120,
            "downloadCount": 634,
            "useCount": 556,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.3
        ],
        [
            "id": "MiniSize",
            "carabinerName": "미니 사이즈",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "작고 귀여운 미니 카라비너",
            "maxKeyringCount": 3,
            "tags": ["미니", "#작음"],
            "price": 0,
            "downloadCount": 1456,
            "useCount": 1234,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.25
        ],
        [
            "id": "LargeCapacity",
            "carabinerName": "라지 캐퍼시티",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "많이 걸 수 있는 대용량 카라비너",
            "maxKeyringCount": 10,
            "tags": ["대용량", "#큼"],
            "price": 250,
            "downloadCount": 445,
            "useCount": 367,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.4
        ],
        [
            "id": "PastelPink",
            "carabinerName": "파스텔 핑크",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "부드러운 핑크 카라비너",
            "maxKeyringCount": 5,
            "tags": ["귀여움", "#핑크"],
            "price": 80,
            "downloadCount": 867,
            "useCount": 723,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.3
        ],
        [
            "id": "BlackMatte",
            "carabinerName": "블랙 매트",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "세련된 블랙 매트 카라비너",
            "maxKeyringCount": 6,
            "tags": ["심플", "#블랙"],
            "price": 0,
            "downloadCount": 1089,
            "useCount": 934,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.33
        ],
        [
            "id": "ClearTransparent",
            "carabinerName": "클리어 투명",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "투명한 아크릴 카라비너",
            "maxKeyringCount": 5,
            "tags": ["투명", "#아크릴"],
            "price": 130,
            "downloadCount": 723,
            "useCount": 612,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.3
        ],
        [
            "id": "FlowerPattern",
            "carabinerName": "플라워 패턴",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "꽃무늬가 새겨진 카라비너",
            "maxKeyringCount": 5,
            "tags": ["귀여움", "#꽃"],
            "price": 110,
            "downloadCount": 556,
            "useCount": 467,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.31
        ],
        [
            "id": "AnimalShape",
            "carabinerName": "동물 모양",
            "carabinerImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "description": "귀여운 동물 모양 카라비너",
            "maxKeyringCount": 4,
            "tags": ["귀여움", "#동물"],
            "price": 160,
            "downloadCount": 678,
            "useCount": 589,
            "keyringXPosition": 0.5,
            "keyringYPosition": 0.29
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
            "tags": ["반짝임", "#별"],
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
            "tags": ["귀여움", "#하트"],
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
            "tags": ["축하", "#파티"],
            "price": 80,
            "downloadCount": 1123,
            "useCount": 978
        ],
        [
            "id": "Snowfall",
            "particleName": "눈 내리는",
            "description": "하얀 눈이 내리는 효과",
            "particleData": "snowfall_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#겨울"],
            "price": 0,
            "downloadCount": 1689,
            "useCount": 1456
        ],
        [
            "id": "Fireworks",
            "particleName": "불꽃놀이",
            "description": "화려한 불꽃 효과",
            "particleData": "fireworks_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["축하", "#불꽃"],
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
            "tags": ["귀여움", "#비눗방울"],
            "price": 70,
            "downloadCount": 1234,
            "useCount": 1067
        ],
        [
            "id": "Rainbow",
            "particleName": "무지개",
            "description": "알록달록 무지개 파티클",
            "particleData": "rainbow_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["컬러풀", "#무지개"],
            "price": 120,
            "downloadCount": 978,
            "useCount": 834
        ],
        [
            "id": "MagicDust",
            "particleName": "마법 가루",
            "description": "신비로운 마법 가루 효과",
            "particleData": "magic_dust_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["마법", "#반짝임"],
            "price": 0,
            "downloadCount": 1478,
            "useCount": 1289
        ],
        [
            "id": "Sakura",
            "particleName": "벚꽃잎",
            "description": "흩날리는 벚꽃잎",
            "particleData": "sakura_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#봄"],
            "price": 90,
            "downloadCount": 1156,
            "useCount": 989
        ],
        [
            "id": "Lightning",
            "particleName": "번개",
            "description": "번쩍이는 번개 효과",
            "particleData": "lightning_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["강렬함", "#번개"],
            "price": 130,
            "downloadCount": 756,
            "useCount": 634
        ],
        [
            "id": "Butterfly",
            "particleName": "나비",
            "description": "날아다니는 나비",
            "particleData": "butterfly_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#나비"],
            "price": 110,
            "downloadCount": 889,
            "useCount": 767
        ],
        [
            "id": "Galaxy",
            "particleName": "은하수",
            "description": "우주 은하수 효과",
            "particleData": "galaxy_particle_data",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["우주", "#은하"],
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
            "tags": ["맑음", "#종"],
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
            "tags": ["부드러움", "#피아노"],
            "price": 80,
            "downloadCount": 1678,
            "useCount": 1456
        ],
        [
            "id": "WaterDrop",
            "soundName": "물방울",
            "description": "똑똑 떨어지는 물방울 소리",
            "soundData": "water_drop_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#물"],
            "price": 0,
            "downloadCount": 1923,
            "useCount": 1712
        ],
        [
            "id": "BirdChirp",
            "soundName": "새소리",
            "description": "상쾌한 새 지저귐",
            "soundData": "bird_chirp_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#새"],
            "price": 60,
            "downloadCount": 1567,
            "useCount": 1389
        ],
        [
            "id": "Chime",
            "soundName": "차임벨",
            "description": "영롱한 차임벨 소리",
            "soundData": "chime_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["맑음", "#차임"],
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
            "tags": ["경쾌함", "#기타"],
            "price": 90,
            "downloadCount": 1123,
            "useCount": 967
        ],
        [
            "id": "WindChime",
            "soundName": "풍경소리",
            "description": "바람에 흔들리는 풍경",
            "soundData": "wind_chime_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["평화로움", "#풍경"],
            "price": 0,
            "downloadCount": 1890,
            "useCount": 1634
        ],
        [
            "id": "Xylophone",
            "soundName": "실로폰",
            "description": "톡톡 실로폰 소리",
            "soundData": "xylophone_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["귀여움", "#실로폰"],
            "price": 70,
            "downloadCount": 1456,
            "useCount": 1267
        ],
        [
            "id": "OceanWave",
            "soundName": "파도소리",
            "description": "잔잔한 파도 소리",
            "soundData": "ocean_wave_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#바다"],
            "price": 120,
            "downloadCount": 1234,
            "useCount": 1089
        ],
        [
            "id": "RainDrop",
            "soundName": "빗소리",
            "description": "촉촉한 빗소리",
            "soundData": "rain_drop_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["자연", "#비"],
            "price": 0,
            "downloadCount": 2056,
            "useCount": 1823
        ],
        [
            "id": "MusicBox",
            "soundName": "오르골",
            "description": "감미로운 오르골 소리",
            "soundData": "music_box_sound.mp3",
            "thumbnail": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Templates%2FacrylicPhoto%2FacrylicPreview.png?alt=media&token=cc1e53cf-9de2-4a32-a50f-f02339999f24",
            "tags": ["감성", "#오르골"],
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
            "tags": ["특별함", "#심장"],
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
