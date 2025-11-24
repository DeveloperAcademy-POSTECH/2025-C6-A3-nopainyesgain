//
//  DataInitializer.swift
//  Keychy
//
//  Firestore에 새 아이템을 추가할 때 사용하는 초기화 도구
//  각 함수의 배열에 데이터를 추가하고 initializeData()를 호출하면 Firestore에 업로드됩니다.
//
//  <길지훈의 따끔한 경고!>
//  isActive는 기본적으로 false로 설정되어 있습니다.
//  배포 전에 Firestore에서 isActive를 true로 변경하세요.
//
//  지원 컬렉션:
//  - Template: 키링 템플릿
//  - Background: 번들 배경
//  - Carabiner: 카라비너
//  - Sound: 사운드 이펙트
//  - Particle: 파티클 이펙트

import FirebaseFirestore

/// 앱 실행 시 한 번만 호출하세요
/// - 원하는 함수를 수정하고, 아래 함수를 호출하세요.
func initializeData() async {
    await initializeTemplates()
    await initializeBackgrounds()
    await initializeCarabiners()
    await initializeParticles()
    await initializeSounds()
}

// MARK: - Background Initialization
func initializeBackgrounds() async {
    let backgrounds: [[String: Any]] = [
        [
            "id": "PurpleKeychy",
            "backgroundName": "퍼플키치",
            "description": "키치의 시그니쳐 퍼플키치 배경화면 입니다.",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Backgrounds%2FPurpleKeychy.png?alt=media&token=9cefda01-b109-40cc-b9fe-7e8b044be394",
            "tags": ["키치"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": true
        ],
        [
            "id": "GreenKeychy",
            "backgroundName": "그린키치",
            "description": "키치의 시그니쳐 그린키치 배경화면 입니다.",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Backgrounds%2FGreenKeychy.png?alt=media&token=5cdf9833-99f2-4a95-8e07-bb4ab1898b3f",
            "tags": ["키치"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": true
        ],
        [
            "id": "WhiteKeychy",
            "backgroundName": "화이트키치",
            "description": "키치의 시그니쳐 화이트키치 배경화면 입니다.",
            "backgroundImage": "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Backgrounds%2FWhiteKeychy.png?alt=media&token=2f19c0e1-0be4-47d2-b84a-34a60d3f1a0f",
            "tags": ["키치"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": true
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
    let db = Firestore.firestore()

    let emptyPositions = [0, 0, 0]

    let carabiners: [[String: Any]] = [

        [
            "id": "BonePink",
            "carabinerName": "뼈다귀 핑크",
            "description": "뼈다귀 핑크 카라비너입니다.",
            "carabinerWidth": 269.0,
            "carabinerX": 66.0,
            "carabinerY": 131.5,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ],

        [
            "id": "PawPink",
            "carabinerName": "발바닥 핑크",
            "description": "발바닥 핑크 카라비너입니다.",
            "carabinerWidth": 334.6,
            "carabinerX": 38.33,
            "carabinerY": 151.61,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ],

        [
            "id": "BoneBlue",
            "carabinerName": "뼈다귀 블루",
            "description": "뼈다귀 블루 카라비너입니다.",
            "carabinerWidth": 269.46,
            "carabinerX": 66.0,
            "carabinerY": 131.5,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ],

        [
            "id": "PawBlue",
            "carabinerName": "발바닥 블루",
            "description": "발바닥 블루 카라비너입니다.",
            "carabinerWidth": 334.6,
            "carabinerX": 38.33,
            "carabinerY": 151.61,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ],

        [
            "id": "CupidHeart",
            "carabinerName": "큐피드 하트",
            "description": "큐피드 하트 카라비너입니다.",
            "carabinerWidth": 351.0,
            "carabinerX": 19.0,
            "carabinerY": 151.5,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ],

        // ☁️ 클라우드 추가
        [
            "id": "CloudKeychy",
            "carabinerName": "클라우드 키치",
            "description": "클라우드 키치 카라비너입니다.",
            "carabinerWidth": 370.16,
            "carabinerX": 16.15,
            "carabinerY": 91.46,

            "carabinerImage": [],
            "carabinerType": "plain",
            "maxKeyringCount": 3,
            "tags": [],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "keyringXPosition": emptyPositions,
            "keyringYPosition": emptyPositions,
            "isActive": false
        ]
    ]

    for carabiner in carabiners {
        guard let id = carabiner["id"] as? String else { continue }

        var data = carabiner
        data.removeValue(forKey: "id")

        do {
            try await db.collection("Carabiner").document(id).setData(data, merge: true)
            print("저장 완료: \(id)")
        } catch {
            print("오류 발생: \(error)")
        }
    }
}



// MARK: - Particle Initialization
func initializeParticles() async {
    let particles: [[String: Any]] = [
        [
            "id": "ExampleParticle",
            "particleName": "예시 파티클",
            "description": "새로운 파티클 설명을 입력하세요",
            "particleData": "https://firebasestorage.googleapis.com/...",
            "thumbnail": "https://firebasestorage.googleapis.com/...",
            "tags": ["태그1", "태그2"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
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
            "id": "ExampleSound",
            "soundName": "예시 사운드",
            "description": "새로운 사운드 설명을 입력하세요",
            "soundData": "https://firebasestorage.googleapis.com/...",
            "thumbnail": "https://firebasestorage.googleapis.com/...",
            "tags": ["태그1", "태그2"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
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

// MARK: - Template Initialization
func initializeTemplates() async {
    let templates: [[String: Any]] = [
        [
            "id": "ExampleTemplate",
            "templateName": "예시 템플릿",
            "description": "새로운 템플릿 설명을 입력하세요",
            "interactions": ["tap"],
            "thumbnailURL": "https://firebasestorage.googleapis.com/...",
            "previewURL": "https://firebasestorage.googleapis.com/...",
            "guidingImageURL": "https://firebasestorage.googleapis.com/...",
            "guidingText": "가이드 텍스트를 입력하세요",
            "tags": ["태그1", "태그2"],
            "price": 0,
            "downloadCount": 0,
            "useCount": 0,
            "isActive": false
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

