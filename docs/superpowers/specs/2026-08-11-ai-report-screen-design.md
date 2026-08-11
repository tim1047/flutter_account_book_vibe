# AI 리포트 화면 — 설계

작성일: 2026-08-11
API 계약: [docs/AI_REPORT_API_SPEC.md](../../AI_REPORT_API_SPEC.md)

## 1. 목적

`ai-report` 도메인 API를 앱에 붙인다. 하단 내비게이션 맨 오른쪽에 `AI` 탭을 만들고,
그 안에서 월간 리포트를 발행하고, 읽고, AI가 물어본 질문에 답한다.

## 2. 범위

**포함**
- 하단 내비 5번째 탭(`AI`) 및 라우트
- 발행 상태 카드 + 지난 리포트 목록 (탭 루트)
- 리포트 상세 (헤드라인 / 지표 4개 / 마크다운 본문 / 액션)
- 프로필 편집 (미답변 질문 열람 + 사용자 확정 구역 전문 편집)
- `_ErrorInterceptor`가 서버 응답 봉투의 메시지를 살리도록 수정

**제외**
- `POST /ai-report/questions` — 외부 cron 전용. 앱은 호출하지 않는다.
- 발행 완료 자동 감지(폴링·푸시). 사용자가 당겨서 새로고침한다.
- 과거 회차 재발행, 임의 월 발행. 발행 대상은 서버가 주는 `publishablePeriod`(전월) 1건뿐이다.
- 목록 무한 스크롤. 회차가 월 1건이라 `limit=20` 한 장이면 1년 8개월치다.

## 3. 결정과 근거

| 결정 | 근거 |
|---|---|
| 탭 루트 = 발행 카드 + 목록 | `GET /status`와 `GET /ai-report`만으로 화면이 완성된다. 발행이라는 행동과 열람이라는 행동이 한 화면에 모인다. |
| 발행 완료 감지는 수동 새로고침 | 서버에 푸시/웹소켓 채널이 없다. 폴링 타이머는 화면 생명주기·백그라운드 전환까지 관리해야 하는데, 월 1회 쓰는 기능에 그만한 상태를 들일 이유가 없다. |
| 마크다운은 `flutter_markdown_plus` | `bodyMd`의 섹션 구성이 회차마다 달라진다(API 스펙 §9). 자체 렌더러는 미지원 문법이 나오는 순간 원문이 노출된다. `flutter_markdown`은 상위 유지보수가 끝나 커뮤니티 포크를 쓴다. |
| 상세 화면은 VM 없이 `FutureBuilder` | 발행 완료된 리포트는 불변이다. 상세에는 시간축 상태가 없어서 `ChangeNotifier`가 `isLoading/errorMessage/data` 세 필드를 손으로 재구현하는 일밖에 하지 않는다. |
| 발행 범위 = 전월 1건 + 재시도 | 회차 선택 UI가 사라지면서 "리포트 없는 과거 회차 404", "미마감 월 500" 같은 예외 경로가 통째로 없어진다. |

## 4. 아키텍처

```
lib/
  core/network/dio_client.dart          (수정) 봉투 메시지 보존
  core/router/app_router.dart           (수정) 5번째 브랜치 + 상세/프로필 라우트
  features/shell/main_shell_screen.dart (수정) 5번째 탭 아이템
  data/models/ai_report_model.dart      (신규) 응답 모델 5개
  data/services/ai_report_service.dart  (신규) 엔드포인트 6개
  features/ai_report/
    ai_report_home_screen.dart          (신규) 탭 루트
    ai_home_viewmodel.dart              (신규) status + 목록 + 전월 상세
    publish_card.dart                   (신규) 발행 카드 + resolvePublishCard
    ai_report_detail_screen.dart        (신규) 상세
    metric_grid.dart                    (신규) 지표 4개 그리드 + 포맷 함수
    ai_profile_screen.dart              (신규) 프로필 편집
    ai_profile_viewmodel.dart           (신규) 프로필 로드/저장
```

의존 방향은 기존과 같다: 화면 → 뷰모델 → 서비스 → `DioClient`. 뷰모델은 수동 생성자 DI,
서비스는 싱글톤이다.

## 5. 데이터 계층

### 5.1 모델 — `lib/data/models/ai_report_model.dart`

전부 `@JsonSerializable(createToJson: false)`, 필드는 응답 JSON과 같은 camelCase라 `fieldRename` 없음.

| 클래스 | 필드 |
|---|---|
| `ReportListItem` | `period`, `headline?`, `publishedAt?` |
| `ReportStatusResponse` | `publishablePeriod`, `published`, `publishedAt?`, `pendingQuestions`, `running` |
| `ReportDetailResponse` | `period`, `status`, `publishedAt?`, `headline?`, `metrics`, `bodyMd?`, `action?`, `errorMessage?` |
| `MetricItem` | `key`, `label`, `value`, `delta`, `verdict`, `format` |
| `ProfileResponse` | `userConfirmed`, `pendingQuestions`, `observations`, `updatedAt` |

- `MetricItem.value` / `delta`는 API가 `int | float` 유니온으로 내린다(스펙 §2.2) → Dart `num`.
  타입을 보고 포맷을 추론하지 않고 항상 `format` 필드를 쓴다.
- `metrics`는 미완료 회차에서 `[]`로 오므로 non-null `List<MetricItem>`, 기본값 `const []`.
- `status`는 문자열 그대로 둔다(`running` / `done` / `failed`). enum 변환은 값을 쓰는 곳이
  `resolvePublishCard` 한 곳뿐이라 불필요하다.
- 날짜는 `"2026-08-02T21:04:11+0900"` — 콜론 없는 오프셋이지만 Dart `DateTime.parse`가
  `+hhmm`을 받으므로 json_serializable 기본 변환으로 통과한다. 테스트로 고정한다.
- `PUT /profile` 요청 바디는 필드 1개라 요청 모델을 만들지 않고 `{'userConfirmed': text}`를
  인라인으로 넘긴다.

### 5.2 서비스 — `lib/data/services/ai_report_service.dart`

`DivisionService`와 동일한 형태: private 생성자 싱글톤 + `_request` 예외 변환 래퍼 +
`ApiResponse.fromJson` 언랩 + `isSuccess` 아니면 `ServerException`.

| 메서드 | 호출 |
|---|---|
| `getStatus()` | `GET /ai-report/status` |
| `getReports({limit = 20, offset = 0})` | `GET /ai-report` |
| `getReport(period)` | `GET /ai-report/{period}` |
| `publish(period)` | `POST /ai-report/{period}` |
| `getProfile()` | `GET /ai-report/profile` |
| `updateProfile(userConfirmed)` | `PUT /ai-report/profile` |

`AppConfig.baseUrl`이 이미 `/account-book`으로 끝나므로 경로는 `/ai-report...`로 시작한다.

`getReport`만 예외 규칙이 있다: **HTTP 404는 던지지 않고 `null`을 반환한다.**
"한 번도 발행을 시도하지 않은 회차"가 정상 상태이고, 발행 카드가 이걸로 미발행과 실패를 가른다.
나머지 메서드는 예외를 그대로 올린다.

### 5.3 `_ErrorInterceptor` 수정 — `lib/core/network/dio_client.dart`

현재 `badResponse` 분기는 `err.response?.statusMessage`만 쓰고 응답 바디를 버린다.
그런데 이 API는 입력 오류도 500 + 메시지 문자열로 내려주므로(스펙 §7.1),
`"아직 종료되지 않은 월은 발행할 수 없습니다"`가 `"[500] Internal Server Error"`로 뭉개진다.

수정: 응답 바디가 `resultMessage`를 가진 `Map`이면 그 값을 예외 메시지로 쓰고,
아니면 지금 동작(`[코드] 상태문구`)을 유지한다. FastAPI 검증 에러(422)는 봉투 형식이 아니라
`detail` 배열이므로(스펙 §7.2) 자동으로 기존 경로로 떨어진다.

**영향 범위는 앱 전체다.** 다른 화면들도 에러 문구가 서버 메시지로 바뀐다. 개선 방향이지만
회귀 가능성이 있으므로 기존 동작(봉투 아닌 응답)을 지키는 테스트를 함께 넣는다.

### 5.4 뷰모델

**`AiHomeViewModel`** — 필드 `isLoading`, `errorMessage`, `status`, `reports`, `publishableDetail`.

`load()`는 2단계다. `publishablePeriod`를 `getStatus()` 응답에서 받아야 세 번째 호출을
만들 수 있으므로 병렬 3개로 묶을 수 없다.

1. `getStatus()`
2. `Future.wait([getReports(), getReport(status.publishablePeriod)])`

두 번째 단계의 `getReport`가 필요한 이유는 스펙 §5.2에 명시돼 있다.
`published:false, running:false`만으로는 "한 번도 시도 안 함"과 "시도했다가 실패함"이
구분되지 않고, 상세를 봐야 `failed`와 `errorMessage`가 나온다.

`publish()`는 `POST /{period}` 응답이 `ReportStatusResponse`와 같은 스키마이므로(스펙 §5.7)
재조회 없이 `status`를 그 값으로 교체한다. `publishableDetail`은 `null`로 비운다.

**`AiProfileViewModel`** — 필드 `profile`, `isLoading`, `isSaving`, `errorMessage`.
`load()`, `save(text)`. `save`는 PUT 응답이 갱신 후 전체 프로필이므로 그 값으로 교체한다.

## 6. 화면

### 6.1 하단 내비게이션

`MainShellScreen._items`에 `(emoji: '🤖', label: 'AI')`를 마지막에 추가하고,
`app_router.dart`의 `StatefulShellRoute.indexedStack`에 5번째 브랜치
(`GoRoute(path: '/aiReport')`)를 추가한다. 레이아웃은 `Expanded`가 5등분으로 알아서 처리한다.

`DataRefreshBus`에는 연결하지 않는다. AI 화면은 가계부 데이터를 변경하지 않고,
리포트 내용은 발행 시점 스냅샷이라 다른 탭의 변경에 영향받지 않는다.

### 6.2 `AiReportHomeScreen` — `/aiReport`

`MainAppBar(showMenuButton: false)` + actions에 프로필 진입 아이콘.
본문은 `RefreshIndicator` 안의 스크롤 뷰.

- **발행 카드** (§6.3)
- `status.pendingQuestions`가 비어 있지 않으면 카드 안에 "AI가 물어본 게 N개 있어" 줄.
  탭하면 프로필 화면으로 이동한다.
- **지난 리포트 목록** — `AppListCard` 재사용. 각 항목은 회차(`2026.06` 형태), `headline`,
  `publishedAt`. 탭하면 상세로 이동한다.
- 목록이 비면 `EmptyView`, 로드 실패면 `ErrorView` + 재시도.

**목록 중복 제거**: 전월이 발행 완료면 발행 카드와 목록 첫 항목이 같은 회차가 된다.
목록에서 `publishablePeriod`와 같은 항목을 뺀다. 순수 함수로 분리해 테스트한다.

### 6.3 발행 카드

입력 `ReportStatusResponse` + `ReportDetailResponse?` → `resolvePublishCard`가 상태 하나로 접는다.

| `running` | `published` | `detail` | 상태 | 표시 |
|---|---|---|---|---|
| `true` | – | – | `running` | "생성 중" + 스피너, 버튼 비활성, "다 되면 아래로 당겨 새로고침" |
| `false` | `true` | – | `done` | 발행 시각 + `[리포트 보기]` |
| `false` | `false` | `null` | `notPublished` | `[발행하기]` |
| `false` | `false` | `status: 'failed'` | `failed` | 실패 사유(예외 타입명) + `[다시 시도]` |

`detail.status`가 `done`인데 `status.published`가 `false`인 조합은 서버가 같은 판정을 쓰므로
발생하지 않는다. 그래도 함수는 `published` 값을 우선해 `done`으로 처리한다.

좁비(10분 초과 `running`) 판정은 서버가 조회 시점에 하고 이미 `failed`로 내려주므로
(스펙 §3.2) 앱에서 경과 시간을 계산하지 않는다.

`[발행하기]` / `[다시 시도]`는 같은 `POST /{period}` 호출이다. 라벨만 다르다.

### 6.4 `AiReportDetailScreen` — `/aiReport/:period`

셸 밖 push. 목록 또는 발행 카드에서 진입한다. `FutureBuilder`로 `getReport(period)` 한 번.

구성: 헤드라인(크게) → 지표 2×2 그리드 → `bodyMd` → `action` 강조 박스.

`getReport`가 `null`을 반환하면(404) `EmptyView`. 진입 경로상 발생하지 않아야 하지만
목록과 서버 상태가 어긋난 경우를 위한 방어다.

**지표 타일** — `verdict`로 색을 고르고(`good` / `caution` / `bad`), `format`으로 값을 포맷한다.

| `format` | 표시 | 비고 |
|---|---|---|
| `currency` | `1,540,000` | 기존 `format_util` 재사용, 소수점 없음 |
| `percent` | `51.2%` | 소수점 1자리 |
| `months` | `4.1개월` | 소수점 1자리 |

`delta`는 부호와 방향 표시를 붙인다(`▲ 320,000` / `▼ 0.3`). `value`가 `num`이라
`currency`에서 `1540000.0`으로 새지 않도록 `toInt()`를 거친다.

### 6.5 `AiProfileScreen` — `/aiReport/profile`

셸 밖 push. 위에서부터:

1. **미답변 질문** — `pendingQuestions` 읽기 전용 카드. 비어 있으면 섹션을 숨긴다.
2. **내가 확정한 내용** — `userConfirmed` 원문을 멀티라인 `TextField`로 편집.
   부분 갱신이 아니라 전면 교체다(스펙 §5.4). 질문에 답하는 행위는 여기에 답을 적는 것이고,
   질문 텍스트가 자동으로 옮겨오지는 않는다.
3. **AI가 관찰한 내용** — `observations` 접이식 읽기 전용.

앱바 저장 버튼은 내용이 바뀌었을 때만 활성. 뒤로가기 시 미저장 변경이 있으면 확인 다이얼로그
(기존 `app_dialogs` 재사용).

## 7. 에러 처리

| 상황 | 처리 |
|---|---|
| 홈 로드 실패 | `ErrorView` + 재시도 (VM `errorMessage`) |
| 발행 요청 실패 | `AppToast`로 서버 메시지, 카드 상태 유지 |
| 상세 로드 실패 | `ErrorView` + 재시도 |
| 상세 404 | `EmptyView` |
| 프로필 로드 404 (`"프로필이 초기화되지 않았습니다"`) | `ErrorView`에 서버 메시지 그대로 |
| 프로필 저장 실패 | `AppToast`만. **입력 내용은 유지한다** |
| 목록 빈 배열 | `EmptyView` |

## 8. 테스트

기존 테스트가 목(mock) 인프라 없이 순수 함수와 데이터 변환만 검증하는 방식이라 그대로 따른다.
네트워크를 태우는 위젯 테스트는 만들지 않는다. 위치는 `test/features/ai_report/`.

1. `resolvePublishCard` — 4개 분기 전부, 특히 `detail == null`(미발행)과
   `detail.status == 'failed'`(실패) 구분
2. 목록 중복 제거 — `publishablePeriod` 항목이 빠지는지, 미발행일 때 목록이 그대로인지
3. 지표 포맷 — `currency` 콤마·정수, `percent` 소수점 1자리, `months` 단위,
   `delta` 부호/방향, `value`가 `num`으로 들어와도 `1540000.0`이 새지 않는지
4. `ReportDetailResponse.fromJson` — API 스펙 §5.6 예시 JSON 그대로 파싱,
   `publishedAt`의 `+0900` 오프셋이 `DateTime`으로 변환되는지, `metrics: []`인 미완료 응답
5. `_ErrorInterceptor` 회귀 — 봉투 바디가 있으면 `resultMessage`를 쓰고,
   없으면 기존 `[코드] 상태문구`를 그대로 쓰는지

## 9. 의존성 추가

```yaml
flutter_markdown_plus: ^1.0.12
```

로컬 환경(Flutter 3.38.9 / Dart 3.10.8)에서 `flutter pub add --dry-run`으로 해석 확인 완료.
`markdown 7.3.1`이 함께 들어온다. `MarkdownStyleSheet`로 `AppColors` / `AppTextStyles` /
Pretendard를 주입해 앱 톤에 맞춘다.
