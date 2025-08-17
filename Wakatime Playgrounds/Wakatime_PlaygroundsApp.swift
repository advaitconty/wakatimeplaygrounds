//
//  Wakatime_PlaygroundsApp.swift
//  Wakatime Playgrounds
//
//  Created by Milind Contractor on 17/8/25.
//

import SwiftUI
import Python
import PythonKit

@main
struct Wakatime_PlaygroundsApp: App {
    init() {
        detectAndConfigurePythonHome()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let sys = Python.import("sys")
                    print("Python Version: \(sys.version_info.major).\(sys.version_info.minor)")
                    print("Python Encoding: \(sys.getdefaultencoding().upper())")
                    print("Python Path: \(sys.path)")
                }
        }
    }
    
    func detectAndConfigurePythonHome() {
        let fm = FileManager.default
        
        func printDebug(_ s: String) { NSLog("[python-detect] %@", s) }
        
        // Basic bundle paths
        if let bundlePath = Bundle.main.bundlePath as String? {
            printDebug("Bundle path: \(bundlePath)")
        }
        if let resourcePath = Bundle.main.resourcePath {
            printDebug("Resource path: \(resourcePath)")
        }
        if let privateFrameworks = Bundle.main.privateFrameworksPath {
            printDebug("PrivateFrameworks path: \(privateFrameworks)")
        }
        let frameworksPath = Bundle.main.bundlePath + "/Frameworks"
        printDebug("Frameworks candidate path: \(frameworksPath)")
        
        // Add candidate roots to search
        var candidates: [String] = []
        if let rp = Bundle.main.resourcePath { candidates.append(rp) }
        if let pf = Bundle.main.privateFrameworksPath { candidates.append(pf) }
        candidates.append(frameworksPath)
        
        // Also include all loaded framework bundles (may include the XCFramework)
        for b in Bundle.allFrameworks {
            candidates.append(b.bundlePath)
            printDebug("AllFrameworks bundle: \(b.bundlePath)")
        }
        
        // Helper to check if a candidate contains lib/pythonX or encodings
        func findPythonHome(in root: String) -> String? {
            guard let enumerator = fm.enumerator(atPath: root) else { return nil }
            while let element = enumerator.nextObject() as? String {
                // look for a few telltale markers
                if element.contains("/lib/python") || element.hasSuffix("/encodings") || element.contains("/site-packages") {
                    // element is a relative path from root (e.g. "Python.framework/Versions/3.12/lib/python3.12/encodings")
                    // compute absolute path to the `lib` parent and return the directory above `lib` (a likely PYTHONHOME)
                    let full = (root as NSString).appendingPathComponent(element)
                    printDebug("Found marker at: \(full) (rel: \(element))")
                    
                    // find the `/lib/` component index in the 'element' string
                    if let libRange = element.range(of: "/lib/") ?? element.range(of: "/lib") {
                        // prefix up to the 'lib' => path that should be PYTHONHOME's parent
                        let prefix = String(element[..<libRange.lowerBound])
                        let pythonHome = (root as NSString).appendingPathComponent(prefix)
                        printDebug("Computed candidate PYTHONHOME: \(pythonHome)")
                        return pythonHome
                    } else {
                        // fallback: if element itself includes "lib/python", climb up to the parent
                        var url = URL(fileURLWithPath: full)
                        // move up until we find a 'lib' folder in path components
                        while url.pathComponents.count > 1 {
                            if url.lastPathComponent == "lib" {
                                let home = url.deletingLastPathComponent().path
                                printDebug("Fallback PYTHONHOME: \(home)")
                                return home
                            }
                            url.deleteLastPathComponent()
                        }
                    }
                }
            }
            return nil
        }
        
        // Search candidates
        var foundHome: String? = nil
        for root in candidates {
            printDebug("Searching root: \(root)")
            if let home = findPythonHome(in: root) {
                foundHome = home
                break
            }
        }
        
        if let home = foundHome {
            printDebug("Setting PYTHONHOME -> \(home)")
            home.withCString { cstr in
                setenv("PYTHONHOME", cstr, 1)
            }
            // Optionally set PYTHONPATH to point to the lib/pythonX path
            // try to locate the actual lib/pythonX dir inside the home
            let libPathCandidate = (home as NSString).appendingPathComponent("lib")
            if fm.fileExists(atPath: libPathCandidate) {
                printDebug("lib exists at: \(libPathCandidate). Setting PYTHONPATH to it.")
                libPathCandidate.withCString { cstr in
                    setenv("PYTHONPATH", cstr, 1)
                }
            }
        } else {
            printDebug("No Python home found in candidates. Bundle contents:")
            if let resourcePath = Bundle.main.resourcePath {
                if let children = try? fm.contentsOfDirectory(atPath: resourcePath) {
                    printDebug("Resources: \(children)")
                }
            }
            if let frameworks = try? fm.contentsOfDirectory(atPath: Bundle.main.bundlePath + "/Frameworks") {
                printDebug("Frameworks: \(frameworks)")
            }
            // don't crash; we can continue but Python will fail later until fixed
        }
    }
}
