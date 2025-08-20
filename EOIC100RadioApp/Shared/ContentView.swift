import SwiftUI

struct ContentView: View {
    @StateObject private var vm = RadioViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(String(format: "%0.2f MHz", vm.frequency))
                .font(.system(.title, design: .rounded).monospacedDigit())

            HStack(spacing: 12) {
                Button("-10") { vm.step(-10) }
                Button("-5") { vm.step(-5) }
                Button("-1") { vm.step(-1) }
                Button("-0.1") { vm.step(-0.1) }
                Button("+0.1") { vm.step(0.1) }
                Button("+1") { vm.step(1) }
                Button("+5") { vm.step(5) }
                Button("+10") { vm.step(10) }
            }

            HStack(spacing: 12) {
                Slider(value: Binding(get: {
                    vm.volume
                }, set: { newVal in
                    vm.setVolume(newVal)
                }), in: 0...15, step: 1) {
                    Text("Volume")
                }
                .frame(maxWidth: 280)

                Toggle(isOn: Binding(get: {
                    vm.isMuted
                }, set: { v in
                    vm.toggleMute(v)
                })) { Text("Mute") }
                .toggleStyle(.switch)
                .frame(width: 120)
            }

            HStack(spacing: 12) {
                Button(vm.isOn ? "Power off" : "Power on") {
                    vm.togglePower()
                }
                Button("Status") {
                    vm.readState()
                }
            }
        }
        .padding()
        .onAppear { vm.readState() }
    }
}


