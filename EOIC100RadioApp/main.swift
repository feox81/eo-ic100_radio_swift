import AppKit
import Foundation
import EOIC100RadioKit

final class AppDelegate: NSObject, NSApplicationDelegate {
	var fm: BesFM?
	var window: NSWindow!
	var freqField: NSTextField!
	var volumeSlider: NSSlider!
	var muteButton: NSButton!
	var powerButton: NSButton!
	var uiTimer: Timer?

	func applicationDidFinishLaunching(_ notification: Notification) {
		fm = BesFM()

		window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 180),
						  styleMask: [.titled, .closable, .miniaturizable],
						  backing: .buffered, defer: false)
		window.center()
		window.title = "EO-IC100 Radio"
		let content = NSView(frame: window.contentView!.bounds)
		content.translatesAutoresizingMaskIntoConstraints = false
		window.contentView = content

		freqField = NSTextField(labelWithString: "---.-- MHz")
		freqField.font = NSFont.monospacedDigitSystemFont(ofSize: 28, weight: .medium)
		freqField.frame = NSRect(x: 20, y: 120, width: 260, height: 30)
		content.addSubview(freqField)

		let up1m = NSButton(title: "+1M", target: self, action: #selector(freqUp1m))
		up1m.frame = NSRect(x: 300, y: 120, width: 90, height: 32)
		let dn1m = NSButton(title: "-1M", target: self, action: #selector(freqDown1m))
		dn1m.frame = NSRect(x: 400, y: 120, width: 90, height: 32)
		let up500k = NSButton(title: "+500K", target: self, action: #selector(freqUp500k))
		up500k.frame = NSRect(x: 300, y: 82, width: 90, height: 32)
		let dn500k = NSButton(title: "-500K", target: self, action: #selector(freqDown500k))
		dn500k.frame = NSRect(x: 400, y: 82, width: 90, height: 32)
		let up100k = NSButton(title: "+100K", target: self, action: #selector(freqUp100k))
		up100k.frame = NSRect(x: 300, y: 44, width: 90, height: 32)
		let dn100k = NSButton(title: "-100K", target: self, action: #selector(freqDown100k))
		dn100k.frame = NSRect(x: 400, y: 44, width: 90, height: 32)

		content.addSubview(up1m); content.addSubview(dn1m)
		content.addSubview(up500k); content.addSubview(dn500k)
		content.addSubview(up100k); content.addSubview(dn100k)

		volumeSlider = NSSlider(value: 6, minValue: 0, maxValue: 15, target: self, action: #selector(volumeChanged))
		volumeSlider.frame = NSRect(x: 20, y: 82, width: 260, height: 20)
		content.addSubview(volumeSlider)

		muteButton = NSButton(title: "Mute", target: self, action: #selector(toggleMute))
		muteButton.frame = NSRect(x: 20, y: 44, width: 100, height: 32)
		content.addSubview(muteButton)

		powerButton = NSButton(title: "Power on", target: self, action: #selector(togglePower))
		powerButton.frame = NSRect(x: 130, y: 44, width: 150, height: 32)
		content.addSubview(powerButton)

		// 초기 UI 렌더 및 주기적 갱신 타이머
		refreshUI()
		uiTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
			self?.refreshUI()
			// 장치가 없다가 꽂힌 경우 자동 연결
			if self?.fm == nil {
				self?.fm = BesFM()
			}
		}
		window.makeKeyAndOrderFront(nil)
	}

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
		} else {
			muteButton.title = "Mute"
		}
	}

	@objc func togglePower() {
		guard let fm else { return }
		if fm.getPower() { fm.setPower(false) }
		else if fm.getRecording() { fm.setRecording(false) }
		else { fm.setPower(true); usleep(200_000); fm.setVolume(6); fm.setChannel(91.5) }
		refreshUI()
	}

	@objc func volumeChanged() { fm?.setVolume(UInt16(volumeSlider.intValue)); refreshUI() }
	@objc func toggleMute() {
		guard let fm else { return }
		fm.setMute(!fm.getMute())
		refreshUI()
	}
	@objc func freqUp1m() { stepFreq(1.0) }
	@objc func freqDown1m() { stepFreq(-1.0) }
	@objc func freqUp500k() { stepFreq(0.5) }
	@objc func freqDown500k() { stepFreq(-0.5) }
	@objc func freqUp100k() { stepFreq(0.1) }
	@objc func freqDown100k() { stepFreq(-0.1) }

	func stepFreq(_ delta: Double) {
		guard let fm else { return }
		var f = fm.getChannel()
		f = min(107.0, max(76.0, f + delta))
		fm.setChannel(f)
		refreshUI()
	}
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()


