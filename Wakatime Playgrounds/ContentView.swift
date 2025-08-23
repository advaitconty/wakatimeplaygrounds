//
//  ContentView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import SwiftUI
import PythonKit

struct ContentView: View {
    @AppStorage("api_url") var api_url = "https://hackatime.hackclub.com/api/hackatime/v1"
    @AppStorage("api_key") var api_key = ""
    @AppStorage("heartbeat_rate_limit_seconds") var heartbeat_rate_limit_seconds = "30"
    @AppStorage("setupFinished") var setupFinished: Bool = false
    var body: some View {
        if !setupFinished {
            SetupView(api_url: $api_url, api_key: $api_key, heartbeat_rate_limit_seconds: $heartbeat_rate_limit_seconds, finishSetup: $setupFinished)
                .transition(.slide)
        } else {
            HomeView(api_url: $api_url, api_key: $api_key, heartbeat_rate_limit_seconds: $heartbeat_rate_limit_seconds)
            .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
}
