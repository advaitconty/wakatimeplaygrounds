//
//  ContentView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import SwiftUI
import PythonKit

struct ContentView: View {
    @AppStorage("wakatimeSetupData") var wakatimeSetupInformation: String = "[settings]\napi_url = https://hackatime.hackclub.com/api/hackatime/v1\napi_key = <your-wakatime-api-key>\nheartbeat_rate_limit_seconds = 30"
    @AppStorage("setupFinished") var setupFinished: Bool = false
    var body: some View {
        if !setupFinished {
            SetupView(wakatimeSettings: $wakatimeSetupInformation, finishSetup: $setupFinished)
                .transition(.slide)
        } else {
            HomeView(wakatimeSettings: $wakatimeSetupInformation)
                .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
}
