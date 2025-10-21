# Keychy 기여 가이드

### **✨✨✨✨Happy Coding! 💻✨✨✨✨**

<img width="300" alt="image" src="https://github.com/user-attachments/assets/3b6cb0db-6b19-4013-9fbb-0cf2c3102e69" />

---

### 브랜치 전략
```
main ← develop ← feature/feat-name
```

### 브랜치 네이밍

- 소문자만 사용
- 타입 뒤에 `/`, 단어는 `-`로 구분
- 예시: `feature/keyring-voice-memo`

### 브랜치 종류

| 타입 | 용도 | 예시 |
|------|------|------|
| `main` | 앱스토어 배포/프로덕션 | - |
| `develop` | 개발 통합 | - |
| `feature/` | 새로운 기능 개발 | `feature/keyring-maker` |
| `bugfix/` | 버그 수정 | `bugfix/keyring-crash` |
| `chore/` | 빌드, 설정 | `chore/setup-ci` |
| `docs/` | 문서 작업 | `docs/readme-update` |
| `refactor/` | 코드 리팩토링 | `refactor/keyring-model` |
| `style/` | UI/UX 스타일링 | `style/button-design` |
| `perf/` | 성능 최적화 | `perf/image-loading` |

### 커밋 컨벤션

| 타입 | 설명 | 예시 |
|------|------|------|
| `feat:` | 새로운 기능 추가 | `feat: 키링에 음성 메모 기능 추가` |
| `fix:` | 버그 수정 | `fix: 컬렉션 화면 크래시 버그 수정` |
| `chore:` | 빌드, 설정 변경 | `chore: 의존성 업데이트` |
| `docs:` | 문서 작업 | `docs: API 가이드 추가` |
| `refactor:` | 코드 리팩토링 | `refactor: KeyringManager 구조 개선` |
| `style:` | 스타일링, UI 변경 | `style: 메인 화면 버튼 디자인 개선` |
| `perf:` | 성능 최적화 | `perf: 이미지 로딩 속도 개선` |

---

### 개발하기

1. `develop`에서 브랜치 생성 **(이슈 to 브랜치 생성)**
2. 개발 & 커밋
3. `develop`으로 PR 생성
4. 2명 승인 받기
5. 머지
