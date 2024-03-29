//
//  File.swift
//  
//
//  Created by Jaccoud Damien on 29.03.24.
//

import Cocoa

public class UpdaterWindow: NSWindow {
    
    let configFileURL: URL
    
    /**
     - parameter url: The URL to the configuration file for the update.
     */
    public init(configFile url: URL) {
        self.configFileURL = url
        Host.configFile = url
        var styleMask = NSWindow.StyleMask()
        styleMask.insert(.titled)
        //styleMask.insert(.closable)
        //styleMask.insert(.miniaturizable)
        //styleMask.insert(.resizable)
        super.init(contentRect: NSMakeRect(0, 0, 440, 146), styleMask: styleMask, backing: .buffered, defer: false)
        
        self.center()
        self.title = Host.updaterName
        self.makeKeyAndOrderFront(self)
        
        let windowDelegate = WindowDelegate()
        self.delegate = windowDelegate
    }
    
    public func create() {
        let updaterView = UpdaterView(frame: self.frame)
        if let contentView = self.contentView {
            
            contentView.addSubview(updaterView)
            
            //        Add the constraints
            updaterView.translatesAutoresizingMaskIntoConstraints = false
            
            updaterView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            updaterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            updaterView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            updaterView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            
            //        Launch the update
            DispatchQueue.main.async {
                Updater.shared.update()
            }
        }
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}
