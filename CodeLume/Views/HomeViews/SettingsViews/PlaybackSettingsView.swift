import SwiftUI

struct PlaybackSettingsView: View {
    @AppStorage(PAUSE) private var pause: Bool = UserDefaultsManager.shared.getPauseStatus()
    @AppStorage(MUTE) private var mute: Bool = UserDefaultsManager.shared.getMuteStatus()
    @AppStorage(VOLUME) private var volume: Double = Double(UserDefaultsManager.shared.getVolume())
    @AppStorage(PAUSE_IF_OTHER_APP_ON_DESKTOP) private var pauseIfOtherAppOnDesktop: Bool = UserDefaultsManager.shared.getPauseIfOtherAppOnDesktopStatus()
    @AppStorage(PAUSE_IF_OTHER_APP_FULL_SCREEN) private var pauseIfOtherAppFullScreen: Bool = UserDefaultsManager.shared.getPauseIfOtherAppFullScreenStatus()
    @AppStorage(PAUSE_IF_BATTERY_POWERED) private var pauseIfBatteryPowered: Bool = UserDefaultsManager.shared.getPauseIfBatteryPoweredStatus()
    @AppStorage(PAUSE_IF_POWER_SAVING) private var pauseIfPowerSaving: Bool = UserDefaultsManager.shared.getPauseIfPowerSavingStatus()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Playback operations")
//            Divider()
//            HStack {
//                Label("Playback mode", systemImage: "repeat")
//                Spacer()
//                MenuButton(label: Text(LocalizedStringKey(playMode))) {
//                    ForEach(PlayMode.allCases, id: \.self) { mode in
//                        Button(action: {
//                            playMode = mode.rawValue
//                        }) {
//                            Text(LocalizedStringKey(mode.rawValue))
//                        }
//                    }
//                }
//                .frame(width: 130)
//            }
//            .padding(.leading, 20)
//            HStack {
//                Label("switchInterval", systemImage: "clock.arrow.circlepath")
//                Spacer()
//                MenuButton(label: Text(LocalizedStringKey(switchInterval))) {
//                    ForEach(Interval.allCases, id: \.self) { interval in
//                        Button(action: {
//                            switchInterval = interval.rawValue
//                        }) {
//                            Text(LocalizedStringKey(interval.rawValue))
//                        }
//                    }
//                }
//                .frame(width: 130)
//            }
//            .padding(.leading, 20)
            IconToggle(iconName: "pause.circle", title: "Pause", isOn: $pause){
                newValue in
                Logger.info("set pause to \(newValue)")
                pause = newValue
                NotificationCenter.default.post(name: .userDefaultChanged, object: nil)
            }
            .padding(.leading)
            
             IconToggle(iconName: "speaker.slash", title: "Mute", isOn: $mute){
                 newValue in
                 Logger.info("set mute to \(newValue)")
                 mute = newValue
                 NotificationCenter.default.post(name: .userDefaultChanged, object: nil)
             }
             .padding(.leading)
            
             HStack() {
                 Image(systemName: "speaker.3")
                     .frame(width: 20, height: 20)
                     .foregroundColor(.primary)
                     .alignmentGuide(.firstTextBaseline) { d in
                         d[.bottom] + 4
                     }
                     .padding(.leading)
                 Text("Volume")
                 Spacer()
             }
             Slider(value: $volume) { editing in
                 if !editing {
                     Logger.info("Current volume: \(volume)")
                     volume = volume
                     NotificationCenter.default.post(name: .userDefaultChanged, object: nil)
                 }
             }
             .padding(.leading, 40)
             .padding(.trailing, 40)
            
            Text("Conditions for pausing playback")
            
            Divider()
            IconToggle(
                iconName: "pause.rectangle",
                title: "Pause the playback when there are other apps on the desktop",
                isOn: $pauseIfOtherAppOnDesktop,
                onChange: { newValue in
                    Logger.info("set pauseIfOtherAppOnDesktop to \(newValue)")
                    pauseIfOtherAppOnDesktop = newValue
                }
            )
            .padding(.leading)
            
            IconToggle(
                iconName: "pause.rectangle.fill",
                title: "Pause the playback when the app is in full-screen mode",
                isOn: $pauseIfOtherAppFullScreen,
                onChange: { newValue in
                    Logger.info("set pauseIfOtherAppFullScreen to \(newValue)")
                    pauseIfOtherAppFullScreen = newValue
                }
            )
            .padding(.leading)
            
            IconToggle(
                iconName: "battery.100",
                title: "Pause the playback when in battery-powered mode",
                isOn: $pauseIfBatteryPowered,
                onChange: { newValue in
                    Logger.info("set pauseIfBatteryPowered to \(newValue)")
                    pauseIfBatteryPowered = newValue
                }
            )
            .padding(.leading)
            
            IconToggle(
                iconName: "battery.25",
                title: "Pause the playback when in power-saving mode",
                isOn: $pauseIfPowerSaving,
                onChange: { newValue in
                    Logger.info("set pauseIfPowerSaving to \(newValue)")
                    pauseIfPowerSaving = newValue
                }
            )
            .padding(.leading)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    PlaybackSettingsView()
}
