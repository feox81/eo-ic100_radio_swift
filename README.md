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

Swift(macOS) 기반 EO-IC100 라디오 제어 프로젝트입니다. Python PoC를 대체하며, 라이브러리(`EOIC100RadioKit`), CLI(`EOIC100RadioCLI`), GUI App(`EOIC100RadioApp`)을 제공합니다.

### 준비 사항
- macOS 13+
- Xcode 15+ 또는 Swift 5.9 toolchain
- 장치: Samsung EO-IC100 (firmware 0.56_050401_aa에서 동작 확인)

### 빌드 및 실행
```bash
cd macos/EOIC100Radio
swift build -c release
swift run EOIC100RadioApp
# 또는
swift run EOIC100RadioCLI power-on
swift run EOIC100RadioCLI set-freq 91.50
```

### 기능
- 전원 온/오프, 녹음 모드 온/오프
- 주파수 설정/조회 (FM)
- 볼륨/음소거 설정
- RDS 상태 조회

### 주의
- 일부 동작에서 팝 노이즈가 발생할 수 있습니다.

### 구조
- `Sources/USBShim`: IOKit을 통한 단순 USB 제어 래퍼
- `Sources/EOIC100RadioKit/BesFM.swift`: 라디오 제어 핵심 API
- `Sources/EOIC100RadioCLI`: CLI 유틸리티
- `Sources/EOIC100RadioApp`: 간단한 AppKit GUI

AM 지원은 현재 공개된 장치 프로토콜 정보가 부족하여 미구현입니다. 하드웨어 명령이 확보되면 동일한 패턴으로 확장 가능합니다.
