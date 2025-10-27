//
//  MKViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/17/25.
// 설명: 이미지 처리 관련 뷰모델(크롭 + 누끼)
// 키링 만들기에 쓰이는 모든 프로퍼티들을 넣어둠.

import SwiftUI
import PhotosUI
import Vision
import Combine

enum KeyringUpdateType {
    case sound
    case particle
}

@Observable
class ArcylicPhotoVM: KeyringViewModelProtocol {
    // 임시 키링 모델 - 아크릴 플로우에서 이펙트 저장용
    var keyring = Keyring() {
        // Combine 브리지로 Scene에 업데이트 전송
        didSet { keyringSubject.send((keyring, .sound)) }
    }
    
    // MARK: - Combine Bridge
    /// @Observable 을 Comebine에 사용하기 위한 브릿지
    let keyringSubject = PassthroughSubject<(Keyring, KeyringUpdateType), Never>()

    // MARK: - 이미지 선택 관련
    var selectedImage: UIImage?
    var fixedImage: UIImage?
    var isProcessing: Bool = false
    var errorMessage: String?

    // MARK: - 크롭 관련
    var cropArea: CGRect = .zero
    var imageViewSize: CGSize = .zero
    var initialCropArea: CGRect?
    var draggedCorner: CropCorner?
    var hasCropAreaBeenSet: Bool = false

    // MARK: - 크롭 결과
    var croppedImage: UIImage = UIImage()
    var removedBackgroundImage: UIImage = UIImage()
    var bodyImage: UIImage? = nil

    let minimumCropSize: CGSize = CGSize(width: 100, height: 100)
    
    //MARK: - 정보 입력
    //TODO: 모델과 연결 필요
    var nameText: String = ""
    var maxTextCount: Int = 30
    var memoText: String = ""
    var maxMemoCount: Int = 100
    var tags: [String] = ["또치", "싱싱", "고양이", "멍멍", "돌고래", "런도", "길", "리엘", "헤븐", "세오쨩"]
    var selectedTags: [String] = []
    
    var createdAt: Date = Date()
    // MARK: - 초기화
    init() {}

    // MARK: - 이미지 데이터 초기화
    func resetImageData() {
        selectedImage = nil
        fixedImage = nil
        cropArea = .zero
        hasCropAreaBeenSet = false
        croppedImage = UIImage()
        removedBackgroundImage = UIImage()
        bodyImage = nil
        errorMessage = nil
    }
    
    //MARK: - 생성일 Date formatter
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: createdAt)
    }
}
