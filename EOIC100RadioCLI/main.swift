import Foundation
import RadioCoreKit

enum Command: String, CaseIterable {
	case powerOn = "power-on"
	case powerOff = "power-off"
	case recordOn = "record-on"
	case recordOff = "record-off"
	case setVol = "set-vol"
	case getVol = "get-vol"
	case mute = "mute"
	case unmute = "unmute"
	case setFreq = "set-freq"
	case getFreq = "get-freq"
	case status = "status"
}

func usage() {
	let cmds = Command.allCases.map { $0.rawValue }.joined(separator: ", ")
	print("Usage: EOIC100RadioCLI [\(cmds)] [args]\nExamples:\n  EOIC100RadioCLI power-on\n  EOIC100RadioCLI set-vol 6\n  EOIC100RadioCLI set-freq 91.50")
}

guard let fm = BesFM() else {
	fputs("Device not found.\n", stderr)
	exit(1)
}

let args = CommandLine.arguments.dropFirst()
guard let cmdStr = args.first, let cmd = Command(rawValue: cmdStr) else {
	usage(); exit(1)
}

switch cmd {
case .powerOn:
	fm.setPower(true)
case .powerOff:
	fm.setPower(false)
case .recordOn:
	fm.setRecording(true)
case .recordOff:
	fm.setRecording(false)
case .setVol:
	guard let vStr = args.dropFirst().first, let v = UInt16(vStr) else { usage(); exit(1) }
	fm.setVolume(v)
case .getVol:
	print(fm.getVolume())
case .mute:
	fm.setMute(true)
case .unmute:
	fm.setMute(false)
case .setFreq:
	guard let fStr = args.dropFirst().first, let f = Double(fStr) else { usage(); exit(1) }
	fm.setChannel(f)
case .getFreq:
	print(String(format: "%.2f", fm.getChannel()))
case .status:
	let s = fm.getStatus()
	switch s.kind {
	case .seek:
		print("seek success: \(s.success == true), freq: \(String(format: "%.2f", s.freqMHz ?? 0)), strength: \(s.strength ?? 0)")
	case .tune:
		print("tune success: \(s.success == true), freq: \(String(format: "%.2f", s.freqMHz ?? 0)), strength: \(s.strength ?? 0)")
	case .rds:
		let hex = s.rds?.map { String(format: "%02x", $0) }.joined() ?? ""
		print("rds error: \(s.error ?? 0), strength: \(s.strength ?? 0), data: \(hex)")
	case .raw:
		print("raw: \(s.raw?.map { String(format: "%02x", $0) }.joined() ?? "")")
	}
}


