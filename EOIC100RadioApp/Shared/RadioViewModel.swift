import Foundation
import Combine

final class RadioViewModel: ObservableObject {
    @Published var frequency: Double = 89.1
    @Published var volume: Double = 6
    @Published var isMuted: Bool = false
    @Published var isOn: Bool = false

    private let service: RadioService
    private var cancellables = Set<AnyCancellable>()

    init(service: RadioService = RadioServiceImpl()) {
        self.service = service
        service.initialize()
        service.setChannelSpacing(.khz100)
        readState()
    }

    func readState() {
        frequency = service.getChannel()
        volume = Double(service.getVolume())
        isMuted = service.getMute()
        isOn = service.getPower() || service.getRecording()
    }

    func step(_ delta: Double) {
        let next = min(107.0, max(76.0, frequency + delta))
        let rounded = (next * 10).rounded() / 10
        frequency = rounded
        service.setChannel(rounded)
    }

    func setVolume(_ v: Double) {
        volume = v
        service.setVolume(UInt16(v))
    }

    func toggleMute(_ v: Bool) {
        isMuted = v
        service.setMute(v)
    }

    func togglePower() {
        if service.getPower() {
            service.setPower(false)
            isOn = false
        } else if service.getRecording() {
            service.setRecording(false)
            isOn = false
        } else {
            service.setPower(true)
            usleep(200_000)
            service.setVolume(UInt16(volume))
            service.setChannel(frequency)
            isOn = true
        }
    }
}


