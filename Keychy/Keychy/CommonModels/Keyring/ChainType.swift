//
//  ChainType.swift
//  KeytschPrototype
//
//  Created by Jini on 10/16/25.
//

import Foundation

enum ChainType {
    case basic
    
    // MARK: - 체인 이름
    var displayName: String {
        switch self {
        case .basic:
            return "기본 체인"
        }
    }
    
    // MARK: - 체인 링크 정보
    struct ChainLink {
        let imageURL: String
        let storagePath: String
        let width: CGFloat
        let height: CGFloat
        
        var size: CGSize {
            CGSize(width: width, height: height)
        }
    }
    
    // MARK: - 짝수/홀수 체인 링크
    /// 짝수 번째에 사용되는 체인 링크 (0, 2, 4, ...)
    var evenLink: ChainLink {
        switch self {
        case .basic:
            return ChainLink(
                imageURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Chains%2FbasicChain1.png?alt=media&token=359912fe-eb2b-43c0-a882-18c07bd25382",
                storagePath: "Chains/basicChain1.png",
                width: 5,
                height: 22
            )
        }
    }
    
    /// 홀수 번째에 사용되는 체인 링크 (1, 3, 5, ...)
    var oddLink: ChainLink {
        switch self {
        case .basic:
            return ChainLink(
                imageURL: "https://firebasestorage.googleapis.com/v0/b/keychy-f6011.firebasestorage.app/o/Chains%2FbasicChain2.png?alt=media&token=9462c923-979a-4aa0-98c5-bbd626bcaf30",
                storagePath: "Chains/basicChain2.png",
                width: 18,
                height: 26
            )
        }
    }
    
    // MARK: - 인덱스로 체인 링크 가져오기
    /// 인덱스에 따라 적절한 체인 링크 반환
    func getLink(at index: Int) -> ChainLink {
        return index % 2 == 0 ? evenLink : oddLink
    }
    
    func createChainLinks(length: Int) -> [ChainLink] {
        return (0..<length).map { index in
            getLink(at: index)
        }
    }
    
    // MARK: - ID로 타입 찾기
    static func fromID(_ id: String) -> ChainType {
        switch id {
        case "p1Ci3kICxyLoP0B7turc":
            return .basic
        default:
            return .basic
        }
    }
}
