//
//  TextFilter.swift
//  Keychy
//
//  욕설 및 부적절한 단어 필터링 유틸리티
//  - 정규식 기반 패턴 매칭 (1차)
//  - JSON 기반 추가 단어 필터링 (2차)
//  - 화이트리스트 오탐 방지
//

import Foundation

class TextFilter {
    static let shared = TextFilter()

    // MARK: - Properties

    /// 욕설 감지 정규식 (강화 버전 - 최대 9자 입력 제한에 맞춤)
    private let profanityPattern = """
    [시씨씪슈쓔쉬쉽쒸쓉][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[바발벌빠빡빨뻘파팔펄]|\
    [섊좆좇졷좄좃좉졽썅춍봊]|[ㅈ조][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}까|\
    ㅅㅣㅂㅏㄹ?|ㅂ[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}ㅅ|\
    [ㅄᄲᇪᄺᄡᄣᄦᇠ]|[ㅅㅆᄴ][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[ㄲㅅㅆᄴㅂ]|\
    [존좉좇][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}나|\
    [자보][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}지|보빨|\
    [봊봋봇봈볻봁봍][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[빨이]|\
    [후훚훐훛훋훗훘훟훝훑][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[장앙]|\
    [엠앰][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}창|애[미비]|애자|\
    [가-탏탑-힣][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}색[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}기|\
    (?:[샊샛세쉐쉑쉨쉒객갞갟갯갰갴겍겎겏겤곅곆곇곗곘곜걕걖걗걧걨걬][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[끼키퀴])|\
    새[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[키퀴]|\
    [병븅][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[신딱딲]|미친[가-닣닥-힣]|[믿밑]힌|\
    [염옘][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}병|\
    [샊샛샜샠섹섺셋셌셐셱솃솄솈섁섂섓섔섘][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}기|\
    [섹섺섻쎅쎆쎇쎽쎾쎿섁섂섃썍썎썏][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[스쓰]|\
    [지야][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}랄|니[애에]미|\
    갈[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}보[^가-힣]|\
    [뻐뻑뻒뻙뻨][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[뀨큐킹낑]|\
    꼬[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}추|곧[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}휴|\
    [가-힣]슬아치|자[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}박꼼|빨통|\
    [사싸](?:이코|가지|[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}까시)|\
    육[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}시[랄럴]|\
    육[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}실[알얼할헐]|즐[^가-힣]|\
    찌[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}(?:질이|랭이)|\
    찐[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}따|\
    찐[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}찌버거|창[녀놈]|\
    [가-힣]{2,}충[^가-힣]|[가-힣]{2,}츙|부녀자|화냥년|환[양향]년|\
    호[ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[구모]|조[선센][징]|조센|\
    [쪼쪽쪾](?:[발빨]이|[바빠]리)|찌끄[레래]기|(?:하악){2,}|하[앍앜]|\
    [낭당랑앙항남담람암함][ㄱ-ㅎㅏ-ㅣ\\s\\-*_.0-9]{0,7}[가-힣]+[띠찌]|\
    느[금급]마|(?<=[^\n])[家哥]|속냐|[tT]l[qQ]kf|Wls|[ㅂ]신|[ㅅ]발|[ㅈ]밥
    """

    private var regex: NSRegularExpression?
    private var additionalBadWords: Set<String> = []
    private var whitelist: Set<String> = []

    // MARK: - Init

    private init() {
        loadRegex()
        loadBadWordsFromJSON()
    }

    // MARK: - Load Methods

    /// 정규식 컴파일
    private func loadRegex() {
        do {
            regex = try NSRegularExpression(
                pattern: profanityPattern,
                options: [.caseInsensitive]
            )
        } catch {
            print("[TextFilter] 정규식 컴파일 실패: \(error)")
        }
    }

    /// JSON 파일에서 추가 욕설 리스트 로드
    private func loadBadWordsFromJSON() {
        guard let url = Bundle.main.url(forResource: "BadWords", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[TextFilter] BadWords.json 로드 실패")
            return
        }

        // 카테고리별 욕설 추출
        if let categories = json["categories"] as? [String: [String]] {
            for (_, words) in categories {
                additionalBadWords.formUnion(words)
            }
        }

        // 화이트리스트 추출
        if let whitelistArray = json["whitelist"] as? [String] {
            whitelist = Set(whitelistArray)
        }

        print("[TextFilter] 로드 완료 - 추가 단어: \(additionalBadWords.count)개, 화이트리스트: \(whitelist.count)개")
    }

    // MARK: - Public Methods

    /// 욕설 포함 여부 체크
    /// - Parameter text: 검사할 텍스트
    /// - Returns: 욕설 포함 시 true
    func containsProfanity(_ text: String) -> Bool {
        // 1. 화이트리스트 체크 (오탐 방지)
        if isInWhitelist(text) {
            return false
        }

        // 2. 정규식 체크
        if let regex = regex {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, range: range) != nil {
                return true
            }
        }

        // 3. 추가 단어 체크
        let lowercasedText = text.lowercased()
        for badWord in additionalBadWords {
            if lowercasedText.contains(badWord.lowercased()) {
                return true
            }
        }

        return false
    }

    /// 유효성 검사 (욕설 체크 + 메시지 리턴)
    /// - Parameter text: 검사할 텍스트
    /// - Returns: (유효성, 에러 메시지)
    func validateText(_ text: String) -> (isValid: Bool, message: String?) {
        if containsProfanity(text) {
            return (false, "부적절한 단어가 포함되어 있어요")
        }
        return (true, nil)
    }

    /// 화이트리스트 체크
    private func isInWhitelist(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return whitelist.contains { lowercasedText.contains($0.lowercased()) }
    }
}
