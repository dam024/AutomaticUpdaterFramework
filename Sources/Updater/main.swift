//
//  File.swift
//  
//
//  Created by Jaccoud Damien on 29.03.24.
//

import Cocoa
import AutomaticUpdaterFramework

let application = NSApplication.shared
application.setActivationPolicy(NSApplication.ActivationPolicy.regular)

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private var window: UpdaterWindow
    override init() {
        let url = URL(fileURLWithPath: "/Users/jaccouddamien/Documents/Developer/AutomaticUpdaterFramework/Sources/Updater/UpdaterConfig.plist")
        self.window = UpdaterWindow(configFile: url)
        super.init()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.window.create()
    }
}

let applicationDelegate = ApplicationDelegate()
application.delegate = applicationDelegate
application.activate(ignoringOtherApps: true)
application.run()
