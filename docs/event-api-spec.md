# 일정(Event) API 스펙

프론트 연동용 백엔드 API 계약서. 서버 구현 기준(2026-08-19)이며 실제 DB 로 동작 검증 완료.

- Base URL: `{host}/account-book`
- 요청·응답 본문 전부 **camelCase**
- 요청 `Content-Type: application/json`

---

## 1. 공통 응답 포맷

성공 응답은 항상 아래 래퍼로 감싼다.

```jsonc
{
  "resultCode": 200,
  "resultMessage": "SUCCESS",
  "resultData": /* 엔드포인트별 페이로드 */,
  "errorMessage": ""
}
```

에러는 두 가지 형태로 나뉜다. **둘 다 처리해야 한다.**

| 상황 | HTTP | 본문 형태 |
|---|---|---|
| 요청값 검증 실패 | **422** | FastAPI 기본 포맷 (`{"detail": [...]}`) — 위 래퍼 아님 |
| 대상 없음 / 서버 오류 | **404**, **500** | 위 래퍼 (`errorMessage` 에 사유) |

422 예시:

```jsonc
{
  "detail": [
    {
      "type": "enum",
      "loc": ["body", "eventTypeCd"],
      "msg": "Input should be 'VACATION', 'HOLIDAY', 'ANNIVERSARY' or 'SCHEDULE'",
      "input": "NOPE"
    }
  ]
}
```

```jsonc
// 기간 역전 등 필드 조합 검증 실패는 loc 이 ["body"] 로만 찍힌다
{
  "detail": [
    { "type": "value_error", "loc": ["body"], "msg": "Value error, endDt 는 strtDt 이후여야 합니다" }
  ]
}
```

404 예시:

```jsonc
{ "resultCode": 404, "resultMessage": "일정을 찾을 수 없습니다", "resultData": null, "errorMessage": "일정을 찾을 수 없습니다" }
```

---

## 2. 공통 데이터 규약

| 항목 | 형식 | 설명 |
|---|---|---|
| 날짜 | `"YYYYMMDD"` 8자리 문자열 | 예 `"20260810"`. 구분자 없음 |
| 시각 | `"HH:MM"` 5자리 문자열 (24시간제) | 예 `"14:00"`, `"09:05"`. `"9:00"`, `"1400"` 은 거부 |
| 종일 일정 | `strtTm`, `endTm` 둘 다 `""` | 하나만 채우면 422 |
| 없는 값 | `null` 아닌 **빈 문자열 `""`** | 전 필드 공통. 응답에 `null` 은 오지 않음 |

### 기간은 양끝 포함(inclusive)

일정 구간은 `[strtDt strtTm, endDt endTm]` 이며 **종료일·종료시각 당시점을 포함**한다.

| 일정 | strtDt | endDt | strtTm | endTm | 의미 |
|---|---|---|---|---|---|
| 8/10 종일 | `20260810` | `20260810` | `""` | `""` | 8/10 하루 |
| 8/10~8/12 휴가 | `20260810` | `20260812` | `""` | `""` | 8/12 **포함** 3일 |
| 8/10 미팅 | `20260810` | `20260810` | `14:00` | `15:30` | 15:30 **까지** |
| 밤샘 일정 | `20260810` | `20260811` | `22:00` | `02:00` | 8/11 02:00 **까지** |

> exclusive 규약(종료일 다음날)을 쓰는 캘린더 라이브러리에 넘길 때는 변환 필요.

### 일정 유형 `eventTypeCd` — 고정 4종

| 코드 | 표기명 (`eventTypeNm`) | 정렬 순서 |
|---|---|---|
| `VACATION` | 휴가 | 1 |
| `HOLIDAY` | 공휴일 | 2 |
| `ANNIVERSARY` | 기념일 | 3 |
| `SCHEDULE` | 일정 | 4 |

이외 값은 **422**. 유형별 색상 등 표현 속성은 서버가 주지 않으며 프론트가 코드로 매핑한다.

### 멤버 `memberId` — 기존 가계부 멤버 공용

| memberId | memberNm |
|---|---|
| `1` | 강원 |
| `2` | 정윤 |
| `3` | 함께 |
| `4` | 아인 |

`""` 는 **공용 일정**(특정 멤버 없음)을 뜻한다. 응답의 `memberNm` 도 `""`.

### 반복 일정 없음

서버에 반복 규칙이 없다. 매년 반복되는 기념일·공휴일도 **해당 연도 건으로 개별 등록**한다.
따라서 목록 응답의 `eventId` 는 항상 실제 저장된 1건이며, 그대로 수정·삭제에 쓸 수 있다.

---

## 3. 엔드포인트

### 3.1 `GET /account-book/event` — 일정 목록

조회 기간과 **겹치는** 일정을 모두 반환한다. 기간 이전에 시작해 기간 안까지 이어지는 여러 날짜
일정도 포함된다(예: 8/11 하루만 조회해도 8/10~8/12 휴가가 나옴).

| 쿼리 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `strtDt` | `YYYYMMDD` | **Y** | 조회 시작일. 누락·형식 오류 시 422 |
| `endDt` | `YYYYMMDD` | **Y** | 조회 종료일 |
| `eventTypeCd` | string | N | 유형 필터. 미지정·`""` = 전체 |
| `memberId` | string | N | 멤버 필터. 미지정·`""` = 전체 |

> `memberId` 필터는 **정확 일치**다. `memberId=1` 로 조회하면 공용 일정(`""`)은 빠진다.
> 공용까지 함께 보려면 필터 없이 받아 프론트에서 거른다.

**정렬**: `strtDt` → `strtTm` → `eventId` 오름차순. 같은 날에서 종일 일정(`strtTm=""`)이
시간 지정 일정보다 먼저 온다.

요청:

```
GET /account-book/event?strtDt=20260801&endDt=20260831&eventTypeCd=&memberId=
```

응답 `resultData`:

```jsonc
[
  {
    "eventId": 2,
    "eventTypeCd": "VACATION",
    "eventTypeNm": "휴가",
    "eventNm": "제주도 여행",
    "contents": "렌터카",
    "strtDt": "20260810",
    "endDt": "20260812",
    "strtTm": "",
    "endTm": "",
    "memberId": "1",
    "memberNm": "강원"
  },
  {
    "eventId": 3,
    "eventTypeCd": "SCHEDULE",
    "eventTypeNm": "일정",
    "eventNm": "미팅",
    "contents": "",
    "strtDt": "20260810",
    "endDt": "20260810",
    "strtTm": "14:00",
    "endTm": "15:30",
    "memberId": "",
    "memberNm": ""
  }
]
```

| 응답 필드 | 타입 | 설명 |
|---|---|---|
| `eventId` | int | 수정·삭제 시 사용하는 식별자 |
| `eventTypeCd` | string | 고정 4종 중 하나 |
| `eventTypeNm` | string | 유형 표기명 (서버 조인 결과) |
| `eventNm` | string | 일정명, 1~100자 |
| `contents` | string | 상세 내용. 없으면 `""` |
| `strtDt` / `endDt` | string | `YYYYMMDD`, 종료일 포함 |
| `strtTm` / `endTm` | string | `HH:MM` 또는 `""`(종일) |
| `memberId` / `memberNm` | string | `""` 면 공용 |

목록이 `contents` 까지 전부 실어 보내므로 **상세 조회 API 는 없다.**

### 3.2 `GET /account-book/event/type` — 유형 목록

유형 코드는 위 표대로 고정이라 프론트가 상수로 들고 있어도 된다. 서버에서 받아 쓰고 싶을 때만 호출.

응답 `resultData`:

```jsonc
[
  { "eventTypeCd": "VACATION",    "eventTypeNm": "휴가",   "sortOrd": 1 },
  { "eventTypeCd": "HOLIDAY",     "eventTypeNm": "공휴일", "sortOrd": 2 },
  { "eventTypeCd": "ANNIVERSARY", "eventTypeNm": "기념일", "sortOrd": 3 },
  { "eventTypeCd": "SCHEDULE",    "eventTypeNm": "일정",   "sortOrd": 4 }
]
```

### 3.3 `POST /account-book/event` — 일정 등록

요청 본문:

```jsonc
{
  "eventTypeCd": "VACATION",
  "eventNm": "제주도 여행",
  "contents": "렌터카 픽업",
  "strtDt": "20260810",
  "endDt": "20260812",
  "strtTm": "",
  "endTm": "",
  "memberId": "1"
}
```

| 필드 | 타입 | 필수 | 기본값 | 제약 |
|---|---|---|---|---|
| `eventTypeCd` | string | **Y** | — | 고정 4종 |
| `eventNm` | string | **Y** | — | 1~100자, 빈 문자열 불가 |
| `contents` | string | N | `""` | 길이 제한 없음 |
| `strtDt` | string | **Y** | — | `YYYYMMDD` |
| `endDt` | string | **Y** | — | `YYYYMMDD`, `>= strtDt` |
| `strtTm` | string | N | `""` | `HH:MM` 또는 `""` |
| `endTm` | string | N | `""` | `HH:MM` 또는 `""` |
| `memberId` | string | N | `""` | `""` = 공용 |

응답 `resultData` = **생성된 `eventId`(int)**.

```jsonc
{ "resultCode": 200, "resultMessage": "SUCCESS", "resultData": 5, "errorMessage": "" }
```

목록 재조회 없이 이 id 로 방금 만든 일정을 화면 상태에 반영할 수 있다.

### 3.4 `PUT /account-book/event/{eventId}` — 일정 수정

**전량 치환**. 본문 필드 구성은 POST 와 완전히 동일하며, 보내지 않은 선택 필드는 기본값(`""`)으로
덮어쓴다. 부분 수정(PATCH) 없음 — 항상 전체 필드를 실어 보낼 것.

```
PUT /account-book/event/3
```

```jsonc
{
  "eventTypeCd": "ANNIVERSARY",
  "eventNm": "결혼기념일",
  "contents": "",
  "strtDt": "20260810",
  "endDt": "20260810",
  "strtTm": "",
  "endTm": "",
  "memberId": ""
}
```

- 시간 지정 일정 → 종일로 되돌리려면 `strtTm`, `endTm` 을 `""` 로 보내면 된다.
- 응답 `resultData: null`
- 없는 `eventId` → **404**

### 3.5 `DELETE /account-book/event/{eventId}` — 일정 삭제

```
DELETE /account-book/event/3
```

- 응답 `resultData: null`
- 없는 `eventId` → **404** (이미 지워진 항목을 다시 지우면 404. 목록 갱신 신호로 쓸 수 있음)
- 복구 불가(hard delete)

---

## 4. 검증 규칙 (전부 422)

등록·수정 공통.

| 규칙 | 위반 예시 | 메시지 |
|---|---|---|
| `eventTypeCd` 고정 4종 | `"NOPE"` | `Input should be 'VACATION', 'HOLIDAY', 'ANNIVERSARY' or 'SCHEDULE'` |
| `eventNm` 1~100자 | `""` | `String should have at least 1 character` |
| 날짜 형식 | `"2026-08-10"`, `"202608"` | `String should match pattern '^\d{8}$'` |
| 시각 형식 | `"1400"`, `"24:00"`, `"9:00"` | `String should match pattern '^(([01]\d\|2[0-3]):[0-5]\d)?$'` |
| `endDt >= strtDt` | `strtDt=20260812`, `endDt=20260810` | `endDt 는 strtDt 이후여야 합니다` |
| 시각 쌍 | `strtTm` 만 지정 | `strtTm 과 endTm 은 함께 지정하거나 함께 비워야 합니다` |
| 같은 날 시각 순서 | `20260810 15:30 ~ 20260810 14:00` | `같은 날이면 endTm 은 strtTm 이후여야 합니다` |

날짜가 다르면 시각 역전은 정상이다(밤샘 일정). 목록 조회의 `strtDt`/`endDt` 도 같은 날짜 형식 검증을 받는다.

---

## 5. 요약

| 메서드 | 경로 | 용도 | 성공 `resultData` |
|---|---|---|---|
| GET | `/account-book/event` | 기간 겹침 목록 | 일정 배열 |
| GET | `/account-book/event/type` | 유형 코드 목록 | 유형 배열 |
| POST | `/account-book/event` | 등록 | 생성된 `eventId` |
| PUT | `/account-book/event/{eventId}` | 전량 수정 | `null` |
| DELETE | `/account-book/event/{eventId}` | 삭제 | `null` |

DB 스키마·설계 근거는 [event-schema-design.md](./event-schema-design.md) 참고.
