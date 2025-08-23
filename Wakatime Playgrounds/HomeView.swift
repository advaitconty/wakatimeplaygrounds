//
//  HomeView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import SwiftUI
import PythonKit
import CustomAlert

struct HomeView: View {
    @Binding var api_url: String
    @Binding var api_key: String
    @Binding var heartbeat_rate_limit_seconds: String
    @State var log: String = ""
    @State var trackerInstance: PythonObject = PythonObject(stringLiteral: "init object")
    @State var isRunning: Bool = false
    @State var showFolderPicker: Bool = false
    @State var selectedFolderURL: URL? = nil
    @State var showNoFolderSelectedError: Bool = false
    let Tracker = Python.import("MainWaka").Tracker
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State var showAlert: Bool = false
    @State var showLocationAccessNotGivenAlert: Bool = false
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @StateObject var backgrounder: Backgrounder = Backgrounder()
    @State var refresh: Bool = false
    @State var openSettings: Bool = false
    
    func debugList(path: URL) {
        let fileManager = FileManager.default
        let didStart = path.startAccessingSecurityScopedResource()
        print("startAccessing ->", didStart)
        do {
            let items = try fileManager.contentsOfDirectory(atPath: path.path)
            print("Readable items:", items)
        } catch {
            print("Failed to list directory:", error)
        }
        if didStart { path.stopAccessingSecurityScopedResource() }
    }
    
    var body: some View {
        Text("Welcome back to Wakatime Playgrounds!")
            .font(.custom("Outfit", size: 36))
        
        if !refresh {
            Text("Your wakatime API key is: \(api_key)")
                .font(.custom("Raleway", size: 16))
                .redacted(reason: .privacy)
                .onAppear {
                    trackerInstance = Tracker(true, api_url, api_key, Int(heartbeat_rate_limit_seconds))
                }
            if let selectedFolderURL {
                Text("Folder selected: \(selectedFolderURL.lastPathComponent)")
                    .font(.custom("Raleway", size: 16))
                    .onAppear {
                        debugList(path: selectedFolderURL)
                    }
            } else {
                Text("No folder selected. Select one to start tracking.")
                    .font(.custom("Raleway", size: 16))
            }
        } else {
            ProgressView()
                .onAppear() {
                    refresh = false
                }
        }
        HStack {
            Button {
                if selectedFolderURL!.startAccessingSecurityScopedResource() {
                    if firstLaunch && !isRunning {
                        showAlert = true
                        firstLaunch = false
                    } else if backgrounder.checkPermissionsStatus() == "Full" {
                        if isRunning {
                            trackerInstance.stop()
                            backgrounder.stopBackgroundLocation()
                            defer { selectedFolderURL!.stopAccessingSecurityScopedResource() }
                        } else {
                            trackerInstance.start(selectedFolderURL!.path, Int(heartbeat_rate_limit_seconds))
                            backgrounder.startBackgroundLocation()
                        }
                    } else if backgrounder.checkPermissionsStatus() == "Partial" {
                        if isRunning {
                            trackerInstance.stop()
                            backgrounder.stopBackgroundLocation()
                            defer { selectedFolderURL!.stopAccessingSecurityScopedResource() }
                        } else {
                            trackerInstance.start(selectedFolderURL!.path, Int(heartbeat_rate_limit_seconds))
                            backgrounder.startBackgroundLocation()
                            backgrounder.requestAlwaysPermissionsForBackgrounding()
                        }
                    } else {
                        showLocationAccessNotGivenAlert = true
                    }
                } else {
                    if isRunning {
                        trackerInstance.stop()
                        backgrounder.stopBackgroundLocation()
                    }
                }
            } label: {
                Text(isRunning ? "Stop" : "Start")
                    .font(.custom("Raleway", size: 16))
            }
            .buttonStyle(.borderedProminent)
            .hoverEffect()
            .disabled(selectedFolderURL == nil)
            
            Button {
                showFolderPicker = true
            } label: {
                Text("Select folder")
                    .font(.custom("Raleway", size: 16))
            }
            .buttonStyle(.borderedProminent)
            .hoverEffect()
            
            Button {
                openSettings = true
            } label: {
                Text("Settings")
                    .font(.custom("Raleway", size: 16))
            }
            .buttonStyle(.borderedProminent)
            .hoverEffect()
        }
        
        VStack {
            ScrollView {
                Text(log)
                    .font(.custom("Google Sans Code", size: 16))
                    .onReceive(timer) { _ in
                        self.log = trackerInstance.get_logs().description
                        self.isRunning =  Bool(trackerInstance.running)!
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(width: 500, height: 500)
        .background {
            Color.black
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
        }
        .customAlert("", isPresented: $showAlert) {
            Text("This app requires background location access")
                .font(.custom("Outfit", size: 36))
            Text("This is so we can continue tracking your files in the background, without letting any limitations kick in while you code on Swift Playgrounds.")
                .font(.custom("Raleway", size: 16))
            Text("Hence, please give 'Always' access to this app. We won't use it for anything other then making sure the app doesn't go down in the background")
                .font(.custom("Raleway", size: 16))
        } actions: {
            Button {
                backgrounder.requestPermissionsForBackgrounding()
            } label: {
                Text("OK!")
                    .font(.custom("Raleway", size: 16))
            }
        }
        .customAlert(isPresented: $showLocationAccessNotGivenAlert) {
            Text("You have not given this app background access.")
                .font(.custom("Outfit", size: 36))
            Text("We ask for this so we can continue tracking your files in the background, without letting any limitations kick in while you code on Swift Playgrounds.")
                .font(.custom("Raleway", size: 16))
            Text("Please grant us 'always' access so we can do so")
                .font(.custom("Raleway", size: 16))
        } actions: {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            } label: {
                Text("Grant access in settings")
                    .font(.custom("Raleway", size: 16))
            }
        }
        .fullScreenCover(isPresented: $showFolderPicker) {
            DocumentPicker(selectedURL: $selectedFolderURL)
        }
        .sheet(isPresented: $openSettings) {
            SettingsView(api_url: $api_url, api_key: $api_key, heartbeat_rate_limit_seconds: $heartbeat_rate_limit_seconds)
        }
    }
}
