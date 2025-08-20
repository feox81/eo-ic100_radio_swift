# I can't believe it's a radio!

Python proof of concept of using EO-IC100's FM radio function.

Based on decompiled Note10 framework.

Tested on EO-IC100BBEGKR (Korean model of EO-IC100) firmware version 0.56_050401_aa

Functions working:
 - Turn on/off radio
 - Frequency tuning
 - Set volume/mute
 - Get RDS data
 
Todos:
 - Add more function

 
Warning! Sometimes radio makes loud pop sound.





## EO-IC100 Radio (Swift)

macOS용 EO-IC100 라디오 제어 프로젝트입니다. Python PoC를 대체하며 다음 모듈로 구성됩니다: 라이브러리(`RadioCoreKit`), CLI(`EOIC100RadioCLI`), GUI 앱(`EOIC100RadioApp`).

### 요구 사항
- macOS 13+
- Xcode 15+ (Swift 5.9 toolchain)
- 장치: Samsung EO-IC100 (확인된 펌웨어: 0.56_050401_aa)

### 프로젝트 구성
- `EOIC100RadioApp/`: AppKit 기반 GUI 애플리케이션
  - 주파수 표시 및 단계 버튼(+0.1/+1/+5/+10 MHz), 볼륨 슬라이더, 음소거, 전원 토글
  - 즐겨찾기 저장/삭제, 마지막 채널 자동 복원
  - 자동 스캔(Scan & Save): 76.0~107.0 MHz 대역을 0.2 MHz 코스 스캔 후 ±0.2 정밀 탐색, 동적 임계치(노이즈 플로어 기반)로 후보 채널을 즐겨찾기에 병합 저장

- `EOIC100RadioCLI/`: 커맨드라인 도구
  - 전원/녹음 모드, 볼륨/음소거, 주파수 설정/조회, 상태 조회(RDS 포함)

- `RadioCore/`: Swift Package (SwiftPM)
  - `Sources/RadioCoreKit/BesFM.swift`: 고수준 라디오 제어 API
  - `Sources/USBShim/`: IOKit + CoreFoundation을 사용하는 C 래퍼(USB 제어, 인터럽트 IN)
  - `Package.swift`: `USBShim`(C 타겟)과 `RadioCoreKit`(Swift 타겟)을 정의

- `project.yml`: XcodeGen 설정 (이미 `.xcodeproj`가 포함되어 있으나 필요 시 재생성 가능)

### 빌드
Xcode 또는 xcodebuild로 `App`/`CLI`를 빌드하고, SwiftPM로 코어 라이브러리만 단독 빌드할 수 있습니다.

- Xcode로 열기
  - `EOIC100Radio.xcodeproj`를 열고 `EOIC100RadioApp` 또는 `EOIC100RadioCLI` 스킴을 선택해 빌드/실행

- XcodeGen(선택)
  - `brew install xcodegen`
  - 루트에서 `xcodegen generate` 실행 후 `.xcodeproj` 열기

- xcodebuild로 CLI 빌드
  ```bash
  xcodebuild -scheme EOIC100RadioCLI -configuration Release -derivedDataPath build | cat
  ./build/Build/Products/Release/EOIC100RadioCLI status
  ```

- xcodebuild로 App 빌드
  ```bash
  xcodebuild -scheme EOIC100RadioApp -configuration Release -derivedDataPath build | cat
  open ./build/Build/Products/Release/EOIC100RadioApp.app
  ```

- SwiftPM로 코어만 빌드(RadioCoreKit)
  ```bash
  cd RadioCore
  swift build -c release
  ```

### 실행 및 사용법
- GUI(App): 빌드된 `EOIC100RadioApp.app`을 실행합니다.
  - 전원 토글 시 초기 볼륨 6, 기본 채널 89.1 MHz로 설정됩니다.
  - 즐겨찾기는 `UserDefaults`에 저장되며 앱 재실행 시 복원됩니다.

- CLI: 장치가 연결되어 있어야 하며, 장치를 찾지 못하면 "Device not found."를 stderr로 출력하고 종료합니다.
  ```bash
  # 전원/녹음
  ./EOIC100RadioCLI power-on
  ./EOIC100RadioCLI power-off
  ./EOIC100RadioCLI record-on
  ./EOIC100RadioCLI record-off

  # 볼륨/음소거
  ./EOIC100RadioCLI set-vol 6
  ./EOIC100RadioCLI get-vol
  ./EOIC100RadioCLI mute
  ./EOIC100RadioCLI unmute

  # 주파수
  ./EOIC100RadioCLI set-freq 91.50
  ./EOIC100RadioCLI get-freq

  # 상태(RDS/튜닝/시크 결과 등)
  ./EOIC100RadioCLI status
  ```

### 기능 요약
- 전원 온/오프, 녹음 모드 온/오프(서로 배타적으로 동작)
- 주파수 설정/조회(FM, 내부 표현은 0.01 MHz 단위)
- 볼륨(0~15) 및 음소거 설정
- RDS/튜닝/시크 상태 조회
- GUI의 자동 스캔 및 즐겨찾기 관리

### 장치/USB 참고
- USB Vendor ID: 0x04e8 (Samsung)
- 지원 Product ID: 0xa054, 0xa059, 0xa05b
- 내부적으로 IOKit(Control Transfer) 및 Interrupt IN 파이프를 사용합니다.

### 제한 및 주의
- 일부 동작에서 팝 노이즈가 발생할 수 있습니다.
- AM 대역은 공개된 프로토콜 정보가 부족하여 미구현입니다. 관련 명령 확보 시 동일 패턴으로 확장 가능합니다.

