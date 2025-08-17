//
//  SetupView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import PythonKit
import SwiftUI

struct SetupView: View {
    @Binding var wakatimeSettings: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Text("Welcome to Wakatime Playgrounds!")
                .font(.custom("Outfit", size: 36))
            Text("Let's get you set up. Please start by entering you Wakatime server API key and server URL.")
                .font(.custom("Raleway", size: 16))
            HStack {
                Text("~/.wakatime.cfg")
                    .font(.custom("Google Sans Code", size: 16))
                Spacer()
            }
            
            TextEditor(text: $wakatimeSettings)
                .font(.custom("Google Sans Code", size: 16))
                .textFieldStyle(.roundedBorder)
            
            Button {
               dismiss()
            } label: {
                Text("Start working!")
            }
        }
        .frame(width: 600)
    }
}

#Preview {
    SetupView(wakatimeSettings: .constant("[settings]\napi_url = https://hackatime.hackclub.com/api/hackatime/v1\napi_key = <your-wakatime-api-key>\nheartbeat_rate_limit_seconds = 30"))
}
