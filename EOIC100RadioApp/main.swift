import AppKit
import Foundation
import RadioCoreKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	var fm: BesFM?
	var window: NSWindow!
	var freqField: NSTextField!
	var volumeSlider: NSSlider!
	var muteButton: NSButton!
	var powerButton: NSButton!
	var uiTimer: Timer?

	// 스캔 상태/UI
	var isScanning: Bool = false
	var scanCancelRequested: Bool = false
	var scanProgressLabel: NSTextField!
	var scanSpinner: NSProgressIndicator!

	// 채널 관리
	var favoriteScroll: NSScrollView!
	var favoriteChipsContainer: NSStackView!
	var scanButton: NSButton!
	let favoritesKey = "EOIC100Radio.FavoriteFrequencies"
	let lastChannelKey = "EOIC100Radio.LastFrequency"

	func applicationDidFinishLaunching(_ notification: Notification) {
		fm = BesFM()
		fm?.setChannelSpacing(.khz100)

		window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 260),
						  styleMask: [.titled, .closable, .miniaturizable],
						  backing: .buffered, defer: false)
		window.center()
		window.title = "EO-IC100 Radio"
		window.delegate = self
		let content = NSView(frame: window.contentView!.bounds)
		content.translatesAutoresizingMaskIntoConstraints = false
		window.contentView = content

		freqField = NSTextField(labelWithString: "---.-- MHz")
		freqField.font = NSFont.monospacedDigitSystemFont(ofSize: 28, weight: .medium)
		freqField.frame = NSRect(x: 20, y: 210, width: 260, height: 30)
		content.addSubview(freqField)

		// 즐겨찾기 영역(스크롤)
		favoriteChipsContainer = NSStackView()
		favoriteChipsContainer.orientation = .horizontal
		favoriteChipsContainer.alignment = .centerY
		favoriteChipsContainer.spacing = 8
		favoriteChipsContainer.frame = NSRect(x: 0, y: 0, width: 520, height: 28)

		favoriteScroll = NSScrollView(frame: NSRect(x: 20, y: 176, width: 520, height: 28))
		favoriteScroll.hasHorizontalScroller = true
		favoriteScroll.hasVerticalScroller = false
		favoriteScroll.borderType = .noBorder
		favoriteScroll.drawsBackground = false
		favoriteScroll.documentView = favoriteChipsContainer
		content.addSubview(favoriteScroll)

		scanButton = NSButton(title: "Scan & Save", target: self, action: #selector(scanAndSave))
		scanButton.frame = NSRect(x: 560, y: 210, width: 100, height: 28)
		content.addSubview(scanButton)

		// 스캔 진행 표시
		scanSpinner = NSProgressIndicator()
		scanSpinner.style = .spinning
		scanSpinner.controlSize = .small
		scanSpinner.frame = NSRect(x: 560, y: 182, width: 16, height: 16)
		scanSpinner.isDisplayedWhenStopped = false
		content.addSubview(scanSpinner)

		scanProgressLabel = NSTextField(labelWithString: "")
		scanProgressLabel.font = NSFont.systemFont(ofSize: 11)
		scanProgressLabel.textColor = .secondaryLabelColor
		scanProgressLabel.frame = NSRect(x: 580, y: 176, width: 100, height: 24)
		content.addSubview(scanProgressLabel)

		let up10 = NSButton(title: "+10 MHz", target: self, action: #selector(freqUp10m))
		up10.frame = NSRect(x: 300, y: 210, width: 90, height: 28)
		let dn10 = NSButton(title: "-10 MHz", target: self, action: #selector(freqDown10m))
		dn10.frame = NSRect(x: 400, y: 210, width: 90, height: 28)

		let up5 = NSButton(title: "+5 MHz", target: self, action: #selector(freqUp5m))
		up5.frame = NSRect(x: 300, y: 180, width: 90, height: 28)
		let dn5 = NSButton(title: "-5 MHz", target: self, action: #selector(freqDown5m))
		dn5.frame = NSRect(x: 400, y: 180, width: 90, height: 28)

		let up1 = NSButton(title: "+1 MHz", target: self, action: #selector(freqUp1m))
		up1.frame = NSRect(x: 300, y: 150, width: 90, height: 28)
		let dn1 = NSButton(title: "-1 MHz", target: self, action: #selector(freqDown1m))
		dn1.frame = NSRect(x: 400, y: 150, width: 90, height: 28)

		let up01 = NSButton(title: "+0.1 MHz", target: self, action: #selector(freqUp01m))
		up01.frame = NSRect(x: 300, y: 120, width: 90, height: 28)
		let dn01 = NSButton(title: "-0.1 MHz", target: self, action: #selector(freqDown01m))
		dn01.frame = NSRect(x: 400, y: 120, width: 90, height: 28)

		content.addSubview(up10); content.addSubview(dn10)
		content.addSubview(up5); content.addSubview(dn5)
		content.addSubview(up1); content.addSubview(dn1)
		content.addSubview(up01); content.addSubview(dn01)

		volumeSlider = NSSlider(value: 6, minValue: 0, maxValue: 15, target: self, action: #selector(volumeChanged))
		volumeSlider.frame = NSRect(x: 20, y: 120, width: 260, height: 20)
		content.addSubview(volumeSlider)

		muteButton = NSButton(title: "Mute", target: self, action: #selector(toggleMute))
		muteButton.frame = NSRect(x: 20, y: 84, width: 100, height: 28)
		content.addSubview(muteButton)

		powerButton = NSButton(title: "Power on", target: self, action: #selector(togglePower))
		powerButton.frame = NSRect(x: 130, y: 84, width: 150, height: 28)
		content.addSubview(powerButton)

		let addFav = NSButton(title: "Add Favorite", target: self, action: #selector(addFavorite))
		addFav.frame = NSRect(x: 20, y: 52, width: 120, height: 24)
		content.addSubview(addFav)
		let clearFav = NSButton(title: "Clear Favorites", target: self, action: #selector(clearFavorites))
		clearFav.frame = NSRect(x: 150, y: 52, width: 140, height: 24)
		content.addSubview(clearFav)

		loadFavoritesUI()
		applyInitialChannel()

		// 초기 UI 렌더 및 주기적 갱신 타이머
		refreshUI()
		uiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
			self?.refreshUI()
			if let self, self.fm == nil {
				self.fm = BesFM(); self.fm?.setChannelSpacing(.khz100)
				self.applyInitialChannel()
			}
		}
		window.makeKeyAndOrderFront(nil)
	}

	func applyInitialChannel() {
		guard let fm else { return }
		let saved = UserDefaults.standard.double(forKey: lastChannelKey)
		let initial = saved > 0 ? saved : 89.1
		fm.setChannel(initial)
	}

	func saveLastChannel(_ f: Double) {
		UserDefaults.standard.set(f, forKey: lastChannelKey)
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

	func applicationWillTerminate(_ notification: Notification) {
		if let f = fm?.getChannel() { saveLastChannel(f) }
		guard let fm else { return }
		if fm.getRecording() { fm.setRecording(false) }
		if fm.getPower() { fm.setPower(false) }
	}

	func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }

	func refreshUI() {
		let isConnected = (fm != nil)
		let isOn = (fm?.getPower() == true || fm?.getRecording() == true) && isConnected
		powerButton.title = isOn ? "Power off" : "Power on"
		volumeSlider.isEnabled = isOn
		muteButton.isEnabled = isOn
		if isOn, let f = fm?.getChannel() {
			freqField.stringValue = String(format: "%0.2f MHz", f)
		} else {
			freqField.stringValue = isConnected ? "Standby" : "Not connected"
		}
		if isConnected {
			let isMuted = fm?.getMute() == true
			muteButton.title = isMuted ? "Unmute" : "Mute"
			volumeSlider.doubleValue = Double(fm?.getVolume() ?? 6)
		}
	}

	@objc func togglePower() {
		guard let fm else { return }
		if fm.getPower() { fm.setPower(false) }
		else if fm.getRecording() { fm.setRecording(false) }
		else { fm.setPower(true); usleep(200_000); fm.setVolume(6); fm.setChannel(89.1) }
		refreshUI()
	}

	@objc func volumeChanged() { fm?.setVolume(UInt16(volumeSlider.intValue)); refreshUI() }
	@objc func toggleMute() { fm?.setMute(!(fm?.getMute() ?? false)); refreshUI() }

	@objc func freqUp10m() { stepFreq(10.0) }
	@objc func freqDown10m() { stepFreq(-10.0) }
	@objc func freqUp5m() { stepFreq(5.0) }
	@objc func freqDown5m() { stepFreq(-5.0) }
	@objc func freqUp1m() { stepFreq(1.0) }
	@objc func freqDown1m() { stepFreq(-1.0) }
	@objc func freqUp01m() { stepFreq(0.1) }
	@objc func freqDown01m() { stepFreq(-0.1) }

	func roundToStep(_ value: Double, step: Double) -> Double {
		let inv = 1.0 / step
		return (value * inv).rounded() / inv
	}

	func stepFreq(_ delta: Double) {
		guard let fm else { return }
		var f = fm.getChannel()
		f = min(107.0, max(76.0, f + delta))
		let normalized = roundToStep(f, step: 0.1)
		fm.setChannel(normalized)
		saveLastChannel(normalized)
		refreshUI()
	}

	// 즐겨찾기 저장/로드/UI
	func loadFavorites() -> [Double] {
		(UserDefaults.standard.array(forKey: favoritesKey) as? [Double]) ?? []
	}
	func saveFavorites(_ arr: [Double]) {
		UserDefaults.standard.set(arr, forKey: favoritesKey)
	}
	func loadFavoritesUI() {
		favoriteChipsContainer.arrangedSubviews.forEach { favoriteChipsContainer.removeArrangedSubview($0); $0.removeFromSuperview() }
		for f in loadFavorites() {
			let row = NSStackView()
			row.orientation = .horizontal
			row.alignment = .centerY
			row.spacing = 4

			let btn = NSButton(title: String(format: "%.1f", f), target: self, action: #selector(favoriteTapped(_:)))
			btn.bezelStyle = .rounded
			btn.setButtonType(.momentaryPushIn)
			btn.identifier = NSUserInterfaceItemIdentifier(rawValue: String(f))

			let del = NSButton(title: "×", target: self, action: #selector(removeFavorite(_:)))
			del.bezelStyle = .texturedRounded
			del.font = NSFont.systemFont(ofSize: 11, weight: .regular)
			del.contentTintColor = .secondaryLabelColor
			del.identifier = NSUserInterfaceItemIdentifier(rawValue: String(f))

			row.addArrangedSubview(btn)
			row.addArrangedSubview(del)
			favoriteChipsContainer.addArrangedSubview(row)
		}
		favoriteChipsContainer.layoutSubtreeIfNeeded()
		let fit = favoriteChipsContainer.fittingSize
		favoriteChipsContainer.setFrameSize(NSSize(width: max(520, fit.width), height: max(28, fit.height)))
		favoriteScroll.documentView = favoriteChipsContainer
		favoriteScroll.contentView.scroll(to: NSPoint(x: 0, y: 0))
		favoriteScroll.reflectScrolledClipView(favoriteScroll.contentView)
	}

	@objc func removeFavorite(_ sender: NSButton) {
		guard let text = sender.identifier?.rawValue, let f = Double(text) else { return }
		var arr = loadFavorites()
		arr.removeAll(where: { abs($0 - f) < 0.0001 })
		saveFavorites(arr)
		loadFavoritesUI()
	}
	@objc func favoriteTapped(_ sender: NSButton) {
		guard let text = sender.identifier?.rawValue, let f = Double(text) else { return }
		fm?.setChannel(f)
		saveLastChannel(f)
		refreshUI()
	}
	@objc func addFavorite() {
		guard let f = fm?.getChannel() else { return }
		var arr = loadFavorites()
		if !arr.contains(where: { abs($0 - f) < 0.0001 }) { arr.append(f); arr.sort() }
		saveFavorites(arr)
		loadFavoritesUI()
	}
	@objc func clearFavorites() {
		saveFavorites([]); loadFavoritesUI()
	}

	// 스캔 기능(비동기): 76.0~107.0 범위 0.1 MHz 스텝으로 RSSI 측정, 임계치 이상 저장
	@objc func scanAndSave() {
		guard let fm else { return }
		if isScanning {
			scanCancelRequested = true
			return
		}
		isScanning = true
		scanCancelRequested = false
		updateScanUI(active: true, status: "Preparing…")

		let wasOn = fm.getPower()
		DispatchQueue.global(qos: .userInitiated).async {
			if !wasOn { fm.setPower(true); usleep(200_000) }

			let bandStart = 76.0, bandEnd = 107.0
			func avgRSSI(at f: Double, samples: Int = 3) -> Double {
				fm.setChannel(f)
				usleep(120_000)
				var total: Int = 0
				for _ in 0..<samples {
					total += Int(fm.getRssi())
					usleep(20_000)
				}
				return Double(total) / Double(samples)
			}

			// 1) 노이즈 플로어 추정 후 동적 임계치 설정
			var probes: [Double] = []
			let probeCount = 20
			for i in 0..<probeCount {
				if self.scanCancelRequested { break }
				let f = bandStart + (bandEnd - bandStart) * (Double(i) / Double(probeCount - 1))
				probes.append(avgRSSI(at: self.roundToStep(f, step: 0.1)))
				DispatchQueue.main.async { self.scanProgressLabel.stringValue = "Measuring noise…" }
			}
			let sorted = probes.sorted()
			let q25 = sorted.isEmpty ? 6.0 : sorted[Int(Double(sorted.count - 1) * 0.25)]
			let dynThreshold = max(8.0, q25 + 4.0) // 기본 8, 노이즈+4 여유

			// 2) 코스 스캔(0.2MHz) 후 피크 정밀 탐색(±0.2에서 0.1MHz)
			var found = Set<Double>()
			let coarseStep = 0.2
			let coarseTotal = Int(((bandEnd - bandStart) / coarseStep).rounded()) + 1
			var coarseIdx = 0
			var f = bandStart
			coarseLoop: while f <= bandEnd {
				if self.scanCancelRequested { break coarseLoop }
				let fRounded = self.roundToStep(f, step: 0.1)
				let avg = avgRSSI(at: fRounded, samples: 3)
				if avg >= dynThreshold {
					// 중복 방지: 이미 발견한 것과 0.15MHz 이내면 스킵
					if !found.contains(where: { abs($0 - fRounded) < 0.15 }) {
						// 정밀 탐색으로 최고점 찾기
						var bestF = fRounded
						var bestAvg = avg
						var fine = fRounded - 0.2
						while fine <= fRounded + 0.2 {
							if self.scanCancelRequested { break }
							let fineRounded = self.roundToStep(fine, step: 0.1)
							let a = avgRSSI(at: fineRounded, samples: 3)
							if a > bestAvg {
								bestAvg = a
								bestF = fineRounded
							}
							fine = self.roundToStep(fine + 0.1, step: 0.1)
						}
						found.insert(self.roundToStep(bestF, step: 0.1))
						// 발견 주파수 주변은 건너뛰기
						f = bestF + 0.3
						coarseIdx += 2
						let pct = min(100, Int((Double(coarseIdx) / Double(coarseTotal)) * 100.0))
						DispatchQueue.main.async {
							self.scanProgressLabel.stringValue = String(format: "%.1f MHz · %d%% (found:%d)", bestF, pct, found.count)
						}
						continue
					}
				}
				coarseIdx += 1
				let pct = min(100, Int((Double(coarseIdx) / Double(coarseTotal)) * 100.0))
				DispatchQueue.main.async {
					self.scanProgressLabel.stringValue = String(format: "%.1f MHz · %d%%", fRounded, pct)
				}
				f = self.roundToStep(f + coarseStep, step: 0.1)
			}

			if !wasOn { fm.setPower(false) }
			let favorites = self.loadFavorites()
			let merged = Array(Set(favorites + Array(found))).sorted()
			DispatchQueue.main.async {
				self.saveFavorites(merged)
				self.loadFavoritesUI()
				self.updateScanUI(active: false, status: self.scanCancelRequested ? "Cancelled" : "Done")
				self.isScanning = false
				self.scanCancelRequested = false
			}
		}
	}

	func updateScanUI(active: Bool, status: String) {
		scanButton.title = active ? "Cancel Scan" : "Scan & Save"
		scanButton.isEnabled = true
		if active { scanSpinner.startAnimation(nil) } else { scanSpinner.stopAnimation(nil) }
		scanProgressLabel.stringValue = status
	}
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()


