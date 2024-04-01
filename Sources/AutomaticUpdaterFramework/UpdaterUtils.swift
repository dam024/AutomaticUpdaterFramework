//
//  File.swift
//  
//
//  Created by Jaccoud Damien on 29.03.24.
//

import Cocoa

public class AUStandaloneWindow: NSWindow {
    
    ///Indicate if the window was initialized
    public var isInitialized:Bool = false
    
    public init(frame: NSRect, styleMask: NSWindow.StyleMask) {
        super.init(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)
    }
    
    public func addMainView(_ view: NSView) {
        self.isInitialized = true
        if let contentView = self.contentView {
            
            contentView.addSubview(view)
            
            //        Add the constraints
            view.translatesAutoresizingMaskIntoConstraints = false
            
            view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        }
    }
    
    public func present() {
        self.center()
        self.makeKeyAndOrderFront(self)
    }
}

public class UpdaterWindow: AUStandaloneWindow {
    
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
//        super.init(contentRect: NSMakeRect(0, 0, 440, 146), styleMask: styleMask, backing: .buffered, defer: false)
        super.init(frame: NSMakeRect(0, 0, 440, 146), styleMask: styleMask)
        
        self.title = Host.updaterName
        
        let windowDelegate = WindowDelegate()
        self.delegate = windowDelegate
    }
    
    public func create() {
        let updaterView = UpdaterView(frame: self.frame)
        self.addMainView(updaterView)
        self.present()
        
        //        Launch the update
        DispatchQueue.main.async {
            Updater.shared.update()
        }
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(0)
    }
}

public class AUReleaseNotesWindow: AUStandaloneWindow {
    let releaseNotesURL: URL
    
    /**
     - parameter url: URL to the release notes file
     */
    public init(url: URL) {
        self.releaseNotesURL = url
        var styleMask = NSWindow.StyleMask()
        styleMask.insert(.closable)
        styleMask.insert(.titled)
        super.init(frame: NSMakeRect(0, 0, 400, 500), styleMask: styleMask)
        
        self.title = "Release notes"
        
        self.canHide = false
        self.delegate = self
        self.level = .floating
    }
    
    public func create() {
        let view = AUReleaseNotesView(frame: self.frame, releasNotesURL: self.releaseNotesURL)
        self.addMainView(view)
//        self.present()
    }
}

extension AUReleaseNotesWindow : NSWindowDelegate {

    public func windowDidResignKey(_ notification: Notification) {
        (notification.object as? NSWindow)?.makeKeyAndOrderFront(self)
    }
}
