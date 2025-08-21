//
//  PythonEnvironment.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//


import PythonKit
import Foundation

final class PythonEnvironment {
    static let shared = PythonEnvironment()

    private init() {
        setupScriptsPath()
    }

    private func setupScriptsPath() {
        let sys = Python.import("sys")

        // find Scripts folder in bundle
        if let scriptsURL = Bundle.main.url(forResource: "Scripts", withExtension: nil) {
            let pathStr = Python.str(scriptsURL.path)
            if !sys.path.contains(pathStr) {
                sys.path.insert(0, pathStr)
            }
        } else {
            print("Warning: Scripts folder not found in bundle")
        }
    }

    /// Optional helper to import a module safely
    func importModule(_ name: String) -> PythonObject? {
        return Python.import(name)
    }
}
