//
//  main.swift
//  
//
//  Created by Jaccoud Damien on 30.03.24.
//

import Cocoa
import AutomaticUpdaterFramework

let application = NSApplication.shared
application.setActivationPolicy(NSApplication.ActivationPolicy.regular)

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private var window: AUReleaseNotesWindow
    
    override init() {
        Host.configFile = URL(fileURLWithPath: "/Users/jaccouddamien/Documents/Developer/AutomaticUpdaterFramework/Sources/Updater/UpdaterConfig.plist")//This is required to have everything working...
        let url = URL(string:"https://filesamples.com/samples/document/rtf/sample3.rtf")!
//        let url = URL(fileURLWithPath: "/Users/jaccouddamien/Documents/Developer/AutomaticUpdaterFramework/Sources/ReleaseNotes/releaseNotes.rtf")
        self.window = AUReleaseNotesWindow(url: url)
        super.init()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.window.create()
        self.window.present()
    }
}

let applicationDelegate = ApplicationDelegate()
application.delegate = applicationDelegate
application.activate(ignoringOtherApps: true)
application.run()
