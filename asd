# GitHub 완전 설정 가이드 (A~Z)

이 문서는 sinongbot 프로젝트를 GitHub에서 처음부터 끝까지 설정하는 방법을 안내합니다.
GitHub 저장소 생성부터 브랜치 보호, GHCR 설정, GitHub Actions 자동화까지 모든 것을 다룹니다.

---

## 목차

1. [GitHub 저장소 생성](#1-github-저장소-생성)
   - 1-2. [저장소 일반 설정 (Merge 전략 · 자동 브랜치 삭제)](#1-2-저장소-일반-설정)
2. [로컬 Git 초기 설정](#2-로컬-git-초기-설정)
3. [첫 커밋 & 푸시](#3-첫-커밋--푸시)
4. [브랜치 전략 설정](#4-브랜치-전략-설정)
5. [브랜치 보호 규칙 설정](#5-브랜치-보호-규칙-설정)
6. [GitHub Actions 권한 설정 (GHCR 푸시 허용)](#6-github-actions-권한-설정)
7. [GHCR 이미지 가시성 설정](#7-ghcr-이미지-가시성-설정)
8. [첫 이미지 빌드 & 배포 (수동)](#8-첫-이미지-빌드--배포-수동)
9. [GitHub Actions 자동 빌드 검증](#9-github-actions-자동-빌드-검증)
10. [다른 사람에게 접근 권한 부여](#10-다른-사람에게-접근-권한-부여)
11. [Personal Access Token (PAT) 관리](#11-personal-access-token-pat-관리)
12. [트러블슈팅](#12-트러블슈팅)
13. [저장소 라벨 설정](#13-저장소-라벨-설정)
14. [GitHub Secrets & Variables 관리](#14-github-secrets--variables-관리)
15. [Dependabot & 보안 설정](#15-dependabot--보안-설정)

---

## 1. GitHub 저장소 생성

### 1-1. GitHub 웹에서 생성

1. https://github.com 접속 → 로그인
2. 우상단 `+` 버튼 → **New repository**
3. 설정:
   - **Repository name**: `sinongbot`
   - **Description**: (선택) 예) `Python 3.13 + uv 기반 봇 개발 환경`
   - **Visibility**: `Private` ← **반드시 Private 선택**
   - **Initialize this repository**: 체크 **하지 않음** (로컬에서 push할 것이므로)
4. **Create repository** 클릭

> 저장소 URL 형태: `https://github.com/<your-username>/sinongbot`

---

## 1-2. 저장소 일반 설정

저장소 생성 직후 **Settings → General** 에서 아래 항목을 설정합니다.

### Merge 전략 설정

PR 머지 시 커밋 히스토리를 깔끔하게 유지하기 위해 **Squash merge만 허용**합니다.

1. 저장소 → **Settings** → **General**
2. **Pull Requests** 섹션에서:
   - `Allow merge commits` → **체크 해제**
   - `Allow squash merging` → **체크** ← 유일하게 허용
   - `Allow rebase merging` → **체크 해제**
3. `Default commit message` → **Pull request title** 선택 (PR 제목이 커밋 메시지가 됨)

> Squash merge를 사용하면 feature/* 브랜치의 작업 커밋 여러 개가 main에 하나의 커밋으로 합쳐집니다.
> 이로 인해 `git log --oneline`이 깔끔하게 유지됩니다.

### 자동 브랜치 삭제 설정

PR 머지 후 feature/* 브랜치를 수동으로 삭제하는 번거로움을 없앱니다.

1. **Pull Requests** 섹션 하단:
   - `Automatically delete head branches` → **체크**

> 이제 PR이 머지되면 feature/* 브랜치가 자동으로 삭제됩니다.
> 브랜치는 GitHub에서 복구 가능하므로 안전합니다.

---

## 2. 로컬 Git 초기 설정

### 2-1. Git 전역 설정 (최초 1회)

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global core.autocrlf input   # Windows: true / Mac/Linux: input
```

### 2-2. 로컬 저장소 초기화

```bash
cd c:\sinongbot   # 프로젝트 루트로 이동

git init
git remote add origin https://github.com/LeeJuhyeong424/sinongbot.git
```

### 2-3. .gitignore 확인

`.gitignore` 파일은 프로젝트에 이미 포함되어 있습니다 ([.gitignore](../.gitignore) 참고).
별도로 생성할 필요가 없으며, `git add .` 시 자동으로 적용됩니다.

제외 항목 요약: `src/.venv/`, `src/logs/*`, `src/data/*`, `.env`, `__pycache__/` 등

---

## 3. 첫 커밋 & 푸시

```bash
# 모든 파일 스테이징
git add .

# 현재 상태 확인 (커밋 전 반드시 확인)
git status

# 첫 커밋
git commit -m "chore: initial project setup with Docker base image"

# main 브랜치로 이름 설정 (git 기본값이 master인 경우)
git branch -M main

# GitHub에 푸시
git push -u origin main
```

---

## 4. 브랜치 전략 설정

```bash
# develop 브랜치 생성 & 푸시
git checkout -b develop
git push -u origin develop

# 이후 개발은 develop 브랜치에서 진행
# main은 릴리즈(이미지 배포)할 때만 머지
```

브랜치 구조:
```
main        ← 릴리즈. 자동 빌드 트리거.
  ↑ PR
develop     ← 기본 개발 브랜치
  ↑ PR
feature/*   ← 기능 개발
```

---

## 5. 브랜치 보호 규칙 설정

`main`과 `develop` 브랜치에 직접 커밋을 방지하는 보호 규칙을 설정합니다.

### 5-1. main 브랜치 보호

1. GitHub 저장소 → **Settings** 탭
2. 좌측 메뉴 → **Branches**
3. **Add branch ruleset** 클릭 (또는 **Add rule**)
4. 설정:
   - **Branch name pattern**: `main`
   - **Restrict pushes** 체크
   - **Require a pull request before merging** 체크
     - **Required approvals**: `1` 이상 (혼자 개발 시 0도 가능)
   - **Require status checks to pass** 체크 (Actions 설정 후 활성화)
5. **Create** 클릭

### 5-2. develop 브랜치 보호 (선택)

동일한 방법으로 `develop` 브랜치도 보호 설정 (PR 필수).
혼자 개발 시에는 생략 가능.

---

## 6. GitHub Actions 권한 설정

GitHub Actions가 GHCR에 이미지를 푸시하려면 `packages: write` 권한이 필요합니다.
이 권한은 이미 [.github/workflows/docker-build.yml](../.github/workflows/docker-build.yml)에 선언되어 있지만,
저장소 레벨에서도 허용해야 합니다.

### 6-1. Actions 기본 권한 설정

1. 저장소 → **Settings** → **Actions** → **General**
2. **Workflow permissions** 섹션:
   - **Read and write permissions** 선택
3. **Save** 클릭

### 6-2. GHCR 패키지 쓰기 허용 확인

`docker-build.yml` 파일에 이미 설정되어 있습니다:

```yaml
permissions:
  contents: read
  packages: write   # GHCR 푸시 허용
```

별도 시크릿(Secret) 설정은 필요 없습니다.
`GITHUB_TOKEN`은 GitHub Actions에서 자동 제공됩니다.

---

## 7. GHCR 이미지 가시성 설정

첫 이미지 푸시 후 GitHub → **Packages** 탭에서 패키지가 생성됩니다.
기본적으로 Private 저장소의 이미지는 Private으로 생성됩니다.

### 7-1. 이미지 가시성 확인

1. GitHub → 본인 프로필 → **Packages** 탭
2. `sinongbot` 패키지 클릭
3. 우측 **Package settings** 클릭
4. **Danger Zone** → **Change visibility** 에서 현재 상태 확인

### 7-2. 저장소와 패키지 연결

1. **Package settings** → **Connect Repository** 클릭
2. `sinongbot` 저장소 선택 → 연결

연결하면 저장소 README에 패키지 링크가 표시됩니다.

---

## 8. 첫 이미지 빌드 & 배포 (수동)

GitHub Actions를 기다리지 않고 로컬에서 직접 빌드 & 푸시하는 방법입니다.
초기 `latest` 이미지를 올릴 때 유용합니다.

### 8-1. 로컬에서 GHCR 로그인

```bash
# PAT 발급 방법: docs/GHCR_SETUP.md 참고
# 필요 scope: write:packages, read:packages, delete:packages

echo "<YOUR_PAT>" | docker login ghcr.io -u <your-github-username> --password-stdin
```

### 8-2. multi-arch 이미지 빌드 & 푸시

```bash
# BuildX builder 생성 (최초 1회)
docker buildx create --name sinong-builder --use
docker buildx inspect --bootstrap

# 빌드 & GHCR 푸시 (linux/amd64 + linux/arm64)
docker buildx build \
  --platform linux/amd64,linux/arm64 \

  --tag ghcr.io/<your-github-username>/sinongbot:latest \
  --tag ghcr.io/<your-github-username>/sinongbot:v1.0.0 \
  --push \
  .
```

### 8-3. 이미지 확인

```bash
# 이미지 정보 확인
docker manifest inspect ghcr.io/<your-github-username>/sinongbot:latest
```

GitHub → Packages 탭에서 `sinongbot` 패키지가 생성된 것을 확인합니다.

---

## 9. GitHub Actions 자동 빌드 검증

### 9-1. 자동 빌드 트리거 방법

```bash
# develop 브랜치에서 변경 후
git checkout develop
echo "# test" >> Dockerfile
git add Dockerfile
git commit -m "chore: trigger test build"
git push origin develop
```

GitHub에서:
1. **Pull requests** → **New pull request**
2. **base**: `main` ← **compare**: `develop` 선택
3. **Create pull request** → **Merge pull request** 클릭

### 9-2. Actions 실행 확인

1. 저장소 → **Actions** 탭
2. **Build & Push Docker Image** 워크플로우 클릭
3. 실행 로그 확인:
   - `Set up QEMU` ✅
   - `Set up Docker Buildx` ✅
   - `Login to GitHub Container Registry` ✅
   - `Build and push (linux/amd64 + linux/arm64)` ✅

빌드 시간: 첫 빌드 약 3~5분, 이후 캐시 사용으로 1~2분

### 9-3. 빌드 실패 시 디버깅

**로그 보는 방법**:
- Actions 탭 → 실패한 워크플로우 클릭 → 실패한 Step 클릭 → 로그 확인

**자주 있는 실패 원인**:

| 오류 메시지 | 원인 | 해결 |
|---|---|---|
| `denied: permission_denied` | Actions 권한 부족 | [섹션 6](#6-github-actions-권한-설정) 재확인 |
| `failed to solve: ...` | Dockerfile 문법 오류 | 로컬 빌드로 먼저 검증 |
| `buildx: not found` | BuildX 미설치 | `setup-buildx-action` Step 확인 |

---

## 10. 다른 사람에게 접근 권한 부여

### 10-1. 저장소 접근 권한 (코드 보기/기여)

1. 저장소 → **Settings** → **Collaborators** → **Add people**
2. 상대방 GitHub 유저명 또는 이메일 입력
3. 권한 선택:
   - `Read`: 코드 읽기만
   - `Write`: 브랜치 push 가능
   - `Maintain`: 관리 (설정 변경 제외)

### 10-2. GHCR 이미지 pull 권한

1. GitHub → 본인 프로필 → **Packages** → `sinongbot`
2. **Package settings** → **Manage access** → **Invite teams or people**
3. 유저명 검색 → **Read** 권한 → **Add**

권한을 받은 사람은 본인 PAT(`read:packages`)로 pull 가능:
```bash
echo "<THEIR_PAT>" | docker login ghcr.io -u <their-username> --password-stdin
docker pull ghcr.io/<your-username>/sinongbot:latest
```

---

## 11. Personal Access Token (PAT) 관리

### 11-1. PAT 발급

1. GitHub → 우상단 프로필 → **Settings**
2. 좌측 하단 → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token (classic)**
5. 설정:
   - **Note**: `sinongbot-ghcr-push` (용도 명시)
   - **Expiration**: 90 days (보안 권장) 또는 No expiration
   - **Scopes** 선택:

| 용도 | 필요 Scope |
|---|---|
| 이미지 pull만 | `read:packages` |
| 이미지 빌드/푸시 | `write:packages`, `read:packages` |
| 저장소 접근 포함 | `repo`, `write:packages`, `read:packages` |

6. **Generate token** → 복사 (다시 볼 수 없음!)

### 11-2. PAT 안전하게 저장

```bash
# macOS: Keychain에 저장
security add-generic-password -a <github-username> -s ghcr.io -w <token>

# Linux: pass 또는 환경변수
export GITHUB_PAT=<token>
echo "<token>" | docker login ghcr.io -u <username> --password-stdin

# Windows: 자격 증명 관리자 또는 .env 파일 (git 제외 확인)
```

### 11-3. PAT 만료 전 갱신

1. **Developer settings** → **Personal access tokens** → 기존 토큰 클릭
2. **Regenerate token** 클릭
3. 새 토큰으로 재로그인:
   ```bash
   docker logout ghcr.io
   echo "<new-token>" | docker login ghcr.io -u <username> --password-stdin
   ```

---

## 12. 트러블슈팅

### Actions가 실행되지 않음

**원인**: PR이 `main` 브랜치 대상이 아님  
**해결**: PR의 base 브랜치가 `main`인지 확인. `develop → main` PR이어야 함.

### GHCR 로그인 실패

```
Error response from daemon: unauthorized: authentication required
```
**해결**:
```bash
docker logout ghcr.io
echo "<PAT>" | docker login ghcr.io -u <username> --password-stdin
```

### 이미지 pull 실패 (권한 없음)

```
Error: denied: permission_denied
```
**해결**: 이미지 오너에게 Package access 권한 요청 → [섹션 10](#10-다른-사람에게-접근-권한-부여)

### multi-arch 빌드 실패 (BuildX 없음)

```bash
# Docker Desktop 사용 중이면 BuildX가 기본 포함됨
docker buildx version   # 버전 확인

# 없으면 수동 설치
docker buildx install
```

### Actions 캐시 초기화

```bash
# 저장소 → Actions → Caches 탭에서 삭제
# 또는 캐시 키를 변경해서 강제 초기화
# docker-build.yml에서 cache-from/cache-to 키 변경
```

---

## 빠른 참조: 주요 URL

| 항목 | URL |
|---|---|
| 저장소 | `https://github.com/<username>/sinongbot` |
| Actions | `https://github.com/<username>/sinongbot/actions` |
| Packages (GHCR) | `https://github.com/<username>?tab=packages` |
| Branch protection | `https://github.com/<username>/sinongbot/settings/branches` |
| Actions 권한 | `https://github.com/<username>/sinongbot/settings/actions` |
| Collaborators | `https://github.com/<username>/sinongbot/settings/access` |
| Labels | `https://github.com/<username>/sinongbot/labels` |
| Secrets & Variables | `https://github.com/<username>/sinongbot/settings/secrets/actions` |
| Dependabot alerts | `https://github.com/<username>/sinongbot/security/dependabot` |
| Code security 설정 | `https://github.com/<username>/sinongbot/settings/security_analysis` |

---

## 13. 저장소 라벨 설정

GitHub 이슈와 PR을 분류하기 위한 라벨을 설정합니다.
라벨 이름은 영어, 설명은 한글로 작성합니다.

### 13-1. 라벨 관리 페이지 접근

저장소 → **Issues** 탭 → 우측 **Labels** 버튼 클릭
(또는 `https://github.com/<username>/sinongbot/labels` 직접 접근)

### 13-2. 기존 기본 라벨 처리

GitHub가 자동 생성한 기본 라벨 중 불필요한 것은 삭제하고, 유지할 것은 설명을 한글화합니다.

**삭제할 기본 라벨** (Labels 페이지에서 각 라벨 우측 `Delete` 클릭):

| 삭제 대상 |
|---|
| `duplicate` |
| `good first issue` |
| `help wanted` |
| `invalid` |
| `question` |

**수정할 기본 라벨** (라벨 우측 연필 아이콘 클릭 → 설명 수정):

| 라벨 이름 | 변경할 설명 | 컬러 코드 |
|---|---|---|
| `bug` | 버그 수정 필요 | `d73a4a` |
| `enhancement` | 기존 기능 개선 | `a2eeef` |
| `documentation` | 문서 작업 | `e4e669` |
| `wontfix` | 수정 계획 없음 | `ffffff` |

### 13-3. 신규 라벨 생성

Labels 페이지 우측 상단 **New label** 클릭 → 이름 / 설명 / 컬러 입력 후 **Create label**.

#### 타입 라벨 (작업 종류)

| 라벨 이름 | 설명 | 컬러 코드 |
|---|---|---|
| `feature` | 새 기능 추가 | `0075ca` |
| `chore` | 빌드, 설정, 의존성 변경 | `fef2c0` |

#### 컴포넌트 라벨 (작업 영역)

| 라벨 이름 | 설명 | 컬러 코드 |
|---|---|---|
| `discord-bot` | 디스코드 봇 관련 | `5865f2` |
| `kakao-bot` | 카카오 봇 관련 | `fee500` |
| `web-server` | 웹 서버 관련 | `00a651` |
| `docker` | 도커 이미지 및 컨테이너 관련 | `2496ed` |
| `ci-cd` | GitHub Actions CI/CD 관련 | `2088ff` |

#### 우선순위 라벨

| 라벨 이름 | 설명 | 컬러 코드 |
|---|---|---|
| `priority: high` | 높은 우선순위, 즉시 처리 필요 | `d73a4a` |
| `priority: medium` | 중간 우선순위 | `fbca04` |
| `priority: low` | 낮은 우선순위, 여유 있을 때 처리 | `0e8a16` |

#### 상태 라벨

| 라벨 이름 | 설명 | 컬러 코드 |
|---|---|---|
| `in progress` | 작업 진행 중 | `ededed` |
| `needs review` | 코드 리뷰 필요 | `e99695` |
| `blocked` | 외부 의존성으로 인해 블로킹됨 | `ee0701` |

#### Dependabot 라벨

Dependabot이 자동으로 생성하는 PR에 붙일 라벨입니다.
미리 만들어두면 Dependabot PR에 자동으로 매핑됩니다.

| 라벨 이름 | 설명 | 컬러 코드 |
|---|---|---|
| `dependencies` | 의존성 업데이트 (Dependabot 자동 PR) | `0075ca` |
| `security` | 보안 취약점 관련 업데이트 | `d73a4a` |
| `github-actions` | GitHub Actions 워크플로우 업데이트 | `2088ff` |

### 13-4. 라벨 사용 예시

| PR / 이슈 상황 | 붙일 라벨 |
|---|---|
| 디스코드 봇 버그 수정 | `bug`, `discord-bot` |
| 카카오 봇 신규 기능 | `feature`, `kakao-bot` |
| Dockerfile에 시스템 패키지 추가 | `chore`, `docker` |
| GitHub Actions 워크플로우 수정 | `chore`, `ci-cd` |
| Dependabot Python 패키지 업데이트 PR | `dependencies` |
| Dependabot Actions 버전 업데이트 PR | `dependencies`, `github-actions` |
| 긴급 보안 패치 | `bug`, `security`, `priority: high` |

---

## 14. GitHub Secrets & Variables 관리

봇 프로젝트에서는 Discord 토큰, Kakao API 키 등 민감한 값을 코드에 직접 넣지 않고
GitHub Secrets에 저장한 뒤 Actions에서 참조합니다.

### 14-1. Secrets vs Variables 차이

| 구분 | Secrets | Variables |
|---|---|---|
| 저장 방식 | 암호화 저장 | 평문 저장 |
| 로그 노출 | 자동 마스킹 (`***`) | 그대로 노출될 수 있음 |
| 용도 | 토큰, API 키, 비밀번호 | 환경 이름, 버전, 비민감 설정 |
| 접근 방법 | `${{ secrets.NAME }}` | `${{ vars.NAME }}` |

> 민감한 값은 반드시 **Secrets**에 저장합니다.

### 14-2. Repository Secret 등록

1. 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **Repository secrets** 탭 → **New repository secret** 클릭
3. 설정:
   - **Name**: 대문자 + 언더스코어 조합 (예: `DISCORD_TOKEN`)
   - **Secret**: 실제 토큰/키 값 입력
4. **Add secret** 클릭

> 등록 후 값은 다시 볼 수 없습니다. 분실 시 재발급 후 업데이트해야 합니다.

### 14-3. 봇 프로젝트 Secrets 예시

| Secret 이름 | 용도 |
|---|---|
| `DISCORD_TOKEN` | Discord 봇 토큰 |
| `KAKAO_API_KEY` | 카카오 API 키 |
| `KAKAO_SECRET` | 카카오 REST API 시크릿 |

### 14-4. Actions에서 Secrets 사용

`.github/workflows/docker-build.yml` 에서 Secrets를 환경변수로 주입하는 예시:

```yaml
jobs:
  build:
    steps:
      - name: Build and push
        env:
          DISCORD_TOKEN: ${{ secrets.DISCORD_TOKEN }}
        run: echo "토큰은 로그에 마스킹되어 표시됩니다"
```

또는 Docker run 시 직접 전달:

```yaml
- name: Deploy
  run: |
    docker run -e DISCORD_TOKEN=${{ secrets.DISCORD_TOKEN }} \
               ghcr.io/<username>/sinongbot:latest
```

### 14-5. Secret 업데이트 / 삭제

1. **Settings** → **Secrets and variables** → **Actions**
2. 해당 Secret 우측 연필 아이콘 → 새 값 입력 → **Update secret**
3. 삭제 시 휴지통 아이콘 클릭

---

## 15. Dependabot & 보안 설정

### 15-1. 무료 플랜 (비공개 저장소) 가용 기능

| 기능 | 무료 플랜 지원 여부 |
|---|---|
| Dependabot Alerts (취약점 경고) | ✅ 지원 |
| Dependabot Security Updates (자동 보안 PR) | ✅ 지원 |
| Dependabot Version Updates (버전 업데이트 PR) | ✅ 지원 |
| Dependency Graph | ✅ 지원 |
| Secret Scanning | ❌ 비공개 저장소는 유료 (공개 저장소만 무료) |
| Code Scanning (CodeQL) | ❌ 유료 (Team/Enterprise) |
| GitHub Advanced Security | ❌ 유료 (Team/Enterprise) |

### 15-2. GitHub UI에서 Dependabot 활성화

1. 저장소 → **Settings** → **Code security**
2. 아래 항목을 **Enable** 클릭:
   - **Dependency graph** → Enable
   - **Dependabot alerts** → Enable
   - **Dependabot security updates** → Enable (security updates 자동 PR)

> Dependabot version updates는 `.github/dependabot.yml` 파일이 있으면 자동으로 활성화됩니다.

### 15-3. dependabot.yml 설정 파일

이 프로젝트의 Dependabot 설정은 [.github/dependabot.yml](../.github/dependabot.yml)에 있습니다.

현재 설정된 생태계:

| 생태계 | 업데이트 대상 | 스케줄 |
|---|---|---|
| `github-actions` | `.github/workflows/*.yml`의 Actions 버전 | 매주 월요일 09:00 KST |
| `docker` | `Dockerfile`의 베이스 이미지 버전 | 매주 월요일 09:00 KST |

> Python 의존성 설정은 `pyproject.toml` 추가 시 `dependabot.yml`의 주석 처리된 섹션을 해제하여 활성화합니다.
> (Dependabot은 `uv`를 직접 지원하지 않아 `pip` 생태계로 `pyproject.toml`을 파싱합니다.)

### 15-4. Dependabot PR 처리 방법

Dependabot이 자동으로 PR을 생성하면 다음과 같이 처리합니다:

| 업데이트 종류 | 권장 처리 |
|---|---|
| patch 업데이트 (예: `1.0.0` → `1.0.1`) | Actions 통과 확인 후 즉시 머지 |
| minor 업데이트 (예: `1.0.0` → `1.1.0`) | 변경 로그 확인 후 머지 |
| major 업데이트 (예: `1.0.0` → `2.0.0`) | Breaking change 확인 후 신중하게 머지 |

PR에 자동으로 붙는 라벨: `dependencies` (+ `github-actions` 또는 `docker`)
