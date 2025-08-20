import Foundation
import RadioCoreKit

protocol RadioService {
    func initialize()
    func setPower(_ on: Bool)
    func getPower() -> Bool
    func setRecording(_ on: Bool)
    func getRecording() -> Bool
    func setChannelSpacing(_ spacing: ChannelSpacing)
    func getChannelSpacing() -> UInt8
    func setChannel(_ mhz: Double)
    func getChannel() -> Double
    func setVolume(_ vol: UInt16)
    func getVolume() -> UInt8
    func setMute(_ on: Bool)
    func getMute() -> Bool
}

final class RadioServiceImpl: RadioService {
    private var fm: BesFM?

    func initialize() {
        if fm == nil { fm = BesFM() }
    }

    func setPower(_ on: Bool) { fm?.setPower(on) }
    func getPower() -> Bool { fm?.getPower() == true }
    func setRecording(_ on: Bool) { fm?.setRecording(on) }
    func getRecording() -> Bool { fm?.getRecording() == true }

    func setChannelSpacing(_ spacing: ChannelSpacing) { fm?.setChannelSpacing(spacing) }
    func getChannelSpacing() -> UInt8 { fm?.getChannelSpacing() ?? 0 }

    func setChannel(_ mhz: Double) { fm?.setChannel(mhz) }
    func getChannel() -> Double { fm?.getChannel() ?? 0 }

    func setVolume(_ vol: UInt16) { fm?.setVolume(vol) }
    func getVolume() -> UInt8 { fm?.getVolume() ?? 0 }

    func setMute(_ on: Bool) { fm?.setMute(on) }
    func getMute() -> Bool { fm?.getMute() == true }
}


