import Foundation
import USBShim

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
    private var handle: UnsafeMutableRawPointer?
    private var preparedInterrupt: Bool = false

    public init?() {
        let pids: [UInt16] = [0xa054, 0xa059, 0xa05b]
        let dev: UnsafeMutableRawPointer? = pids.withUnsafeBufferPointer { buf -> UnsafeMutableRawPointer? in
            var crit = usb_shim_match_criteria(vendor_id: 0x04e8, product_ids: buf.baseAddress, product_ids_count: buf.count)
            return usb_open_first(&crit)
        }
        guard let dev else { return nil }
        self.handle = dev
        // Prepare interrupt on interface 4 to match python
        _ = usb_prepare_interrupt_in(self.handle, 4)
        self.preparedInterrupt = true
    }

    deinit {
        if let dev = handle { usb_close(dev) }
    }

    private func set(_ cmd: SetCmd, _ value: UInt16) {
        var local = [UInt8](repeating: 0, count: 1)
        let count = UInt16(local.count)
        local.withUnsafeMutableBufferPointer { ptr in
            _ = usb_control_transfer(self.handle, UInt8(BesCmd.read.rawValue), UInt8(BesCmd.set.rawValue), cmd.rawValue, value, ptr.baseAddress, count, 1000)
        }
    }

    private func get(_ cmd: GetCmd, outLength: Int = Int(BesCmd.getDataLength)) -> [UInt8] {
        var local = [UInt8](repeating: 0, count: outLength)
        let count = UInt16(local.count)
        let read: Int32 = local.withUnsafeMutableBufferPointer { ptr in
            usb_control_transfer(self.handle, UInt8(BesCmd.read.rawValue), UInt8(BesCmd.get.rawValue), cmd.rawValue, BesCmd.getFmIndex, ptr.baseAddress, count, 1000)
        }
        if read > 0 { return Array(local.prefix(Int(read))) } else { return local }
    }

    private func query(outLength: Int = 12) -> [UInt8] {
        var local = [UInt8](repeating: 0, count: outLength)
        let count = UInt16(local.count)
        let read: Int32 = local.withUnsafeMutableBufferPointer { ptr in
            usb_control_transfer(self.handle, UInt8(BesCmd.read.rawValue), UInt8(BesCmd.query.rawValue), 0, 0, ptr.baseAddress, count, 200)
        }
        if read > 0 { return Array(local.prefix(Int(read))) } else { return local }
    }

    // API
    public func setPower(_ on: Bool) {
        guard !getRecording() else { return }
        set(.powerState, on ? 1 : 0)
    }

    public func getPower() -> Bool { get(.fmIcPowerOnState)[0] != 0 }

    public func setRecording(_ on: Bool) {
        guard !getPower() else { return }
        set(.recordingMode, on ? 1 : 0)
    }

    public func getRecording() -> Bool { get(.fmRecordingModeStatus)[0] != 0 }

    public func setBand(_ band: FMBand) { set(.fmBand, band.rawValue) }
    public func getBand() -> UInt8 { get(.currentFmBand)[0] }

    public func setChannelSpacing(_ spacing: ChannelSpacing) { set(.chanSpacing, spacing.rawValue) }
    public func getChannelSpacing() -> UInt8 { get(.currentSpacing)[0] }

    public func setMute(_ on: Bool) { set(.mute, on ? 1 : 0) }
    public func getMute() -> Bool { get(.muteState)[0] != 0 }

    public func setVolume(_ vol: UInt16) { set(.volume, min(15, vol)) }
    public func getVolume() -> UInt8 { get(.currentVolume)[0] }

    public func setMono(_ on: Bool) { set(.monoMode, on ? 1 : 0) }
    public func getMono() -> Bool { get(.forcedMonoState)[0] != 0 }

    public func seekUp() { set(.seekStart, 1) }
    public func seekDown() { set(.seekStart, 2) }
    public func seekStop() { set(.seekStop, 0) }

    public func setChannel(_ mhz: Double) { set(.channel, UInt16(mhz * 100.0)) }
    public func getChannel() -> Double {
        let bytes = get(.currentChannel, outLength: 2)
        let value = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        return Double(value) / 100.0
    }

    public func setRds(_ on: Bool) { set(.rds, on ? 1 : 0) }
    public func getRds() -> Bool { get(.rdsStatus)[0] != 0 }

    public func getRssi() -> UInt8 { get(.currentRssi)[0] }

    public func getStatus() -> BesFMStatus {
        let data = query(outLength: 12)
        guard !data.isEmpty else { return BesFMStatus(kind: .raw, success: nil, freqMHz: nil, strength: nil, error: nil, rds: nil, raw: Data()) }
        switch data[0] {
        case 0: // seek
            if data.count >= 5 {
                let success = data[1] != 0
                let freq = Double(UInt16(data[2]) | (UInt16(data[3]) << 8)) / 100.0
                let strength = data[4]
                return BesFMStatus(kind: .seek, success: success, freqMHz: freq, strength: strength, error: nil, rds: nil, raw: nil)
            }
        case 1: // tune
            if data.count >= 5 {
                let success = data[1] != 0
                let freq = Double(UInt16(data[2]) | (UInt16(data[3]) << 8)) / 100.0
                let strength = data[4]
                return BesFMStatus(kind: .tune, success: success, freqMHz: freq, strength: strength, error: nil, rds: nil, raw: nil)
            }
        case 2: // rds
            if data.count >= 9 {
                let error = data[1]
                let strength = data[2]
                // Reorder like python: rds[1::-1]+rds[3:1:-1]+rds[5:3:-1]+rds[7:5:-1]
                let rds = Data([data[4], data[3], data[6], data[5], data[8], data[7], data[10], data[9]].prefix(8))
                return BesFMStatus(kind: .rds, success: nil, freqMHz: nil, strength: strength, error: error, rds: rds, raw: nil)
            }
        default:
            return BesFMStatus(kind: .raw, success: nil, freqMHz: nil, strength: nil, error: nil, rds: nil, raw: Data(data))
        }
        return BesFMStatus(kind: .raw, success: nil, freqMHz: nil, strength: nil, error: nil, rds: nil, raw: Data(data))
    }
}



