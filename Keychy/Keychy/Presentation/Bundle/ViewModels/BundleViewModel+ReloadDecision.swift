//
//  BundleViewModel+ReloadDecision.swift
//  Keychy
//
//  Created by 김서현 on 1/12/26.
//



extension BundleViewModel {
    // MARK: - 씬 리로드 스킵 판단/최신 구성 저장 로직
    /// 이전 화면에서 전달된 구성 id(return~)가 있고, Detail이 마지막으로 로드한 구성(last~)과 모두 동일하면 true
    /// - true: 동일 구성 -> Detail은 씬 재구성/false 스킵 (View에서 필요 시 isSceneReady를 즉시 true로 복구)
    /// - false: 동일하지 않음 -> 정상 로드 진행
    /// 호출 후 return~Id는 비워짐
    /// return ... Id : 이전 뭉치 상세 화면에서 전달 받은 구성(배경, 카라비너, 키링)들의 id
    func shouldSkipReloadForReturnedConfig() -> Bool {
        guard let returnBGId = returnBackgroundId,
              let returnCBId = returnCarabinerId,
              let returnKRId = returnKeyringsId else {
            return false
        }
        
        // same: 배경, 카라비너, 키링의 id가 변경 된 것이 없으면 true, 변경된 것이 있으면 false를 반환
        let same = (returnBGId == lastBackgroundIdForDetail) &&
                   (returnCBId == lastCarabinerIdForDetail) &&
                   (returnKRId == lastKeyringsIdForDetail)
        // 한 번 사용 후 비움
        if same {
            returnBackgroundId = nil
            returnCarabinerId = nil
            returnKeyringsId = nil
        }
        return same
    }
    
    /// BundleDetailView가 뭉치 로드를 마친 후 현재 구성 id를 last~ForDetail로 저장
    func updateLastConfigIds(
        background: Background?,
        carabiner: Carabiner?,
        keyringDataList: [MultiKeyringScene.KeyringData]
    ) {
        lastBackgroundIdForDetail = makeBackgroundId(background)
        lastCarabinerIdForDetail = makeCarabinerId(carabiner)
        lastKeyringsIdForDetail = makeKeyringsId(keyringDataList)
    }
}
