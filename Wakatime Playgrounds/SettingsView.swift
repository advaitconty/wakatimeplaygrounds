//
//  SettingsView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 23/8/25.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @Binding var api_url: String
    @Binding var api_key: String
    @Binding var heartbeat_rate_limit_seconds: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Wakatime Playgrounds Settings")
                .font(.custom("Outfit", size: 36))
            VStack {
                HStack {
                    Text("[settings]")
                        .font(.custom("Google Sans Code", size: 16))
                    Spacer()
                        .font(.custom("Google Sans Code", size: 16))
                }
                
                HStack {
                    Text("api_url = ")
                        .font(.custom("Google Sans Code", size: 16))
                    TextField("", text: $api_url)
                        .font(.custom("Google Sans Code", size: 16))
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("api_key = ")
                        .font(.custom("Google Sans Code", size: 16))
                    TextField("", text: $api_key)
                        .font(.custom("Google Sans Code", size: 16))
                        .textFieldStyle(.roundedBorder)
                }
                
                HStack {
                    Text("heartbeat_rate_limit_seconds = ")
                        .font(.custom("Google Sans Code", size: 16))
                    TextField("", text: $heartbeat_rate_limit_seconds)
                        .keyboardType(.numberPad)
                        .onReceive(Just(heartbeat_rate_limit_seconds)) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                self.heartbeat_rate_limit_seconds = filtered
                            }
                        }
                        .font(.custom("Google Sans Code", size: 16))
                        .textFieldStyle(.roundedBorder)
                }
                
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
            )
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.custom("Raleway", size: 16))
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SettingsView(api_url: .constant( "https://hackatime.hackclub.com/api/hackatime/v1"), api_key: .constant("<your-wakatime-api-key>"), heartbeat_rate_limit_seconds: .constant("30"))
}
