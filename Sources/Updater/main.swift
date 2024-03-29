//
//  File.swift
//  
//
//  Created by Jaccoud Damien on 29.03.24.
//

import Cocoa
import AutomaticUpdaterFramework

let application = NSApplication.shared

var styleMask = NSWindow.StyleMask()
styleMask.insert(.titled)
//styleMask.insert(.closable)
//styleMask.insert(.miniaturizable)
//styleMask.insert(.resizable)
application.setActivationPolicy(NSApplication.ActivationPolicy.regular)
let window = NSWindow(contentRect: NSMakeRect(0, 0, 440, 146), styleMask: styleMask, backing: .buffered, defer: false)
window.center()
window.title = Host.updaterName
window.makeKeyAndOrderFront(window)

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}

let windowDelegate = WindowDelegate()
window.delegate = windowDelegate

class ApplicationDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow
    init(window: NSWindow) {
        self.window = window
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
//        print(Bundle.allBundles)
//        let updaterViewController = NSStoryboard(name: "Storyboard", bundle: nil).instantiateInitialController() as! UpdaterViewController//UpdaterViewController()
//        let updaterViewController = ViewController()
        let updaterView = UpdaterView(frame: self.window.frame)
        let view = self.window.contentView!
//        self.window.contentView!.addSubview(<#T##view: NSView##NSView#>)
//        self.window.contentViewController = updaterViewController
        view.addSubview(updaterView)
        
//        Add the constraints
        updaterView.translatesAutoresizingMaskIntoConstraints = false
        
        updaterView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        updaterView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        updaterView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        updaterView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
//        Launch the update
        DispatchQueue.main.async {
            Updater.shared.update()
        }
    }
}

let applicationDelegate = ApplicationDelegate(window: window)
application.delegate = applicationDelegate
application.activate(ignoringOtherApps: true)
application.run()
