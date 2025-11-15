import SwiftUI

struct PlaybackSettingsView: View {
    @AppStorage("pause") private var pause: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .pause, object: pause)
        }
    }
    // @AppStorage("mute") private var mute: Bool = false {
    //     didSet {
    //         NotificationCenter.default.post(name: .mute, object: mute)
    //     }
    // }
    @AppStorage("pauseIfOtherAppOnDesktop") private var pauseIfOtherAppOnDesktop: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .pauseIfOtherAppOnDesktop, object: pauseIfOtherAppOnDesktop)
        }
    }
    
    @AppStorage("pauseIfOtherAppFullScreen") private var pauseIfOtherAppFullScreen: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .pauseIfOtherAppFullScreen, object: pauseIfOtherAppFullScreen)
        }
    }
    
    @AppStorage("pauseIfBatteryPowered") private var pauseIfBatteryPowered: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .pauseIfBatteryPowered, object: pauseIfBatteryPowered)
        }
    }
    
    @AppStorage("pauseIfPowerSaving") private var pauseIfPowerSaving: Bool = true {
        didSet {
            NotificationCenter.default.post(name: .pauseIfPowerSaving, object: pauseIfPowerSaving)
        }
    }
    // @AppStorage("volume") private var volume: Double = 1.0 {
    //     didSet {
    //         NotificationCenter.default.post(name: .volume, object: volume)
    //     }
    // }
    
//    @AppStorage("switchInterval") private var switchInterval: String = Interval.fiveMinutes.rawValue {
//        didSet {
//            PlayingManager.shared.setSwitchInterval(Interval(rawValue: switchInterval)!)
//        }
//    }
    
    var body: some View {
        VStack(alignment: .leading) {
//            Text("Playback operations")
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
            }
            .padding(.leading)
            
            // IconToggle(iconName: "speaker.slash", title: "Mute", isOn: $mute){
            //     newValue in
            //     Logger.info("set mute to \(newValue)")
            //     mute = newValue
            // }
            // .padding(.leading)
            
            // HStack() {
            //     Image(systemName: "speaker.3")
            //         .frame(width: 20, height: 20)
            //         .foregroundColor(.primary)
            //         .alignmentGuide(.firstTextBaseline) { d in
            //             d[.bottom] + 4
            //         }
            //         .padding(.leading)
            //     Text("Volume")
            //     Spacer()
            // }
            // Slider(value: $volume) { editing in
            //     if !editing {
            //         Logger.info("Current volume: \(volume)")
            //         volume = volume
            //     }
            // }
            // .padding(.leading, 40)
            // .padding(.trailing, 40)
            
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
