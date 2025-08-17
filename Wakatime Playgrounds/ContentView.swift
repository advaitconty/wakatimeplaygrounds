//
//  ContentView.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import SwiftUI
import PythonKit

struct ContentView: View {
    @State var textItem: String = ""
    var body: some View {
        VStack {
            Text("Welcome to Wakatime Playgrounds!")
            Text(textItem)
                .onAppear {
                    let sys = Python.import("sys")
                    textItem = "\(sys.version)"
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
