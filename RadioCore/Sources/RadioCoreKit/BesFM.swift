import Foundation

// C++ 인터페이스는 Swift에서 직접 호출할 수 없으므로 C 래퍼 심볼을 통해 연결
@_silgen_name("rc_create") private func rc_create() -> UnsafeMutableRawPointer?
@_silgen_name("rc_destroy") private func rc_destroy(_ p: UnsafeMutableRawPointer?)
@_silgen_name("rc_set_power") private func rc_set_power(_ p: UnsafeMutableRawPointer?, _ on: Bool)
@_silgen_name("rc_get_power") private func rc_get_power(_ p: UnsafeMutableRawPointer?) -> Bool
@_silgen_name("rc_set_recording") private func rc_set_recording(_ p: UnsafeMutableRawPointer?, _ on: Bool)
@_silgen_name("rc_get_recording") private func rc_get_recording(_ p: UnsafeMutableRawPointer?) -> Bool
@_silgen_name("rc_set_spacing") private func rc_set_spacing(_ p: UnsafeMutableRawPointer?, _ spacing: UInt16)
@_silgen_name("rc_get_spacing") private func rc_get_spacing(_ p: UnsafeMutableRawPointer?) -> UInt8
@_silgen_name("rc_set_mute") private func rc_set_mute(_ p: UnsafeMutableRawPointer?, _ on: Bool)
@_silgen_name("rc_get_mute") private func rc_get_mute(_ p: UnsafeMutableRawPointer?) -> Bool
@_silgen_name("rc_set_volume") private func rc_set_volume(_ p: UnsafeMutableRawPointer?, _ vol: UInt16)
@_silgen_name("rc_get_volume") private func rc_get_volume(_ p: UnsafeMutableRawPointer?) -> UInt8
@_silgen_name("rc_set_channel") private func rc_set_channel(_ p: UnsafeMutableRawPointer?, _ mhz: Double)
@_silgen_name("rc_get_channel") private func rc_get_channel(_ p: UnsafeMutableRawPointer?) -> Double
@_silgen_name("rc_get_rssi") private func rc_get_rssi(_ p: UnsafeMutableRawPointer?) -> UInt8

public enum BesCmd: UInt16 {
    // Request types
    case write = 64
    case read = 192
    case query = 163
    case get = 162

    // GET subcommands (wValue when bRequest == GET)
    case getFmIcNo = 1
    case getFmIcPowerOnState = 2
    case getCurrentFmBand = 3
    case getCurrentRssi = 4
    case getCurrentSpacing = 5
    case getMuteState = 6
    case getForcedMonoState = 7
    case getCurrentVolume = 8
    case getRdsStatus = 10
    case getCurrentChannel = 13
    case getCurrentSeekingDcThreshold = 14
    case getCurrentSeekingSpikingThreshold = 15
    case getCurrentFmIcInfo = 16
    case getFmRecordingModeStatus = 17
    case getFmProtocolVersion = 18

    // For GET: wIndex must be 0
    static let getFmIndex: UInt16 = 0
    static let getDataLength: UInt16 = 2

    // SET subcommands (wValue when bRequest == SET)
    case set = 161
    case setPowerState = 0x1000 // pseudo discriminator to avoid duplication (not transmitted directly)
    static let setFmIcPowerOff: UInt16 = 0
    static let setFmIcPowerOn: UInt16 = 1
    static let setFmBand: UInt16 = 1
    static let setChanRssiTh: UInt16 = 2
    static let setChanSpacing: UInt16 = 3
    static let setMute: UInt16 = 4
    static let setVolume: UInt16 = 5
    static let setMonoMode: UInt16 = 6
    static let setSeekStart: UInt16 = 7
    static let setSeekUp: UInt16 = 1
    static let setSeekDown: UInt16 = 2
    static let setSeekStop: UInt16 = 8
    static let setChannel: UInt16 = 9
    static let setRds: UInt16 = 10
    static let setDcThres: UInt16 = 11
    static let setSpikeThres: UInt16 = 12
    static let setTestMode: UInt16 = 13
    static let setRecordingMode: UInt16 = 14
    static let setDataLength: UInt16 = 1
}

private enum GetCmd: UInt16 {
    case fmIcNo = 1
    case fmIcPowerOnState = 2
    case currentFmBand = 3
    case currentRssi = 4
    case currentSpacing = 5
    case muteState = 6
    case forcedMonoState = 7
    case currentVolume = 8
    case rdsStatus = 10
    case currentChannel = 13
    case currentSeekingDcThreshold = 14
    case currentSeekingSpikingThreshold = 15
    case currentFmIcInfo = 16
    case fmRecordingModeStatus = 17
    case fmProtocolVersion = 18
}

private enum SetCmd: UInt16 {
    case powerState = 0
    case fmBand = 1
    case chanRssiTh = 2
    case chanSpacing = 3
    case mute = 4
    case volume = 5
    case monoMode = 6
    case seekStart = 7
    case seekStop = 8
    case channel = 9
    case rds = 10
    case dcThres = 11
    case spikeThres = 12
    case testMode = 13
    case recordingMode = 14
}

public enum ChannelSpacing: UInt16 {
    case khz200 = 0
    case khz100 = 1
    case khz50 = 2
}

public enum FMBand: UInt16 {
    case band87to108 = 0
    case band76to107 = 1
    case band76to91 = 2
    case band64to76 = 3
}

public struct BesFMStatus {
    public enum Kind { case seek, tune, rds, raw }
    public var kind: Kind
    public var success: Bool?
    public var freqMHz: Double?
    public var strength: UInt8?
    public var error: UInt8?
    public var rds: Data?
    public var raw: Data?
}

public final class BesFM {
    private var core: UnsafeMutableRawPointer?

    public init?() {
        core = rc_create()
        if core == nil { return nil }
    }

    deinit { rc_destroy(core) }

    public func setPower(_ on: Bool) { rc_set_power(core, on) }
    public func getPower() -> Bool { rc_get_power(core) }

    public func setRecording(_ on: Bool) { rc_set_recording(core, on) }
    public func getRecording() -> Bool { rc_get_recording(core) }

    public func setChannelSpacing(_ spacing: ChannelSpacing) { rc_set_spacing(core, spacing.rawValue) }
    public func getChannelSpacing() -> UInt8 { rc_get_spacing(core) }

    public func setMute(_ on: Bool) { rc_set_mute(core, on) }
    public func getMute() -> Bool { rc_get_mute(core) }

    public func setVolume(_ vol: UInt16) { rc_set_volume(core, vol) }
    public func getVolume() -> UInt8 { rc_get_volume(core) }

    public func setChannel(_ mhz: Double) { rc_set_channel(core, mhz) }
    public func getChannel() -> Double { rc_get_channel(core) }

    public func getRssi() -> UInt8 { rc_get_rssi(core) }
}



