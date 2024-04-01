//
//  ReleaseNotesView.swift
//  
//
//  Created by Jaccoud Damien on 30.03.24.
//

import Cocoa

/**
 A class which manage whether the release notes should be presented or not
 
 This class determines if this is the first opening of the app since the previous update
 */
public class AUReleaseNotesManager {
    ///Key used to save the version of the app that was last open
    private let lastOpenedAppVersionKey: String = "AUReleaseNotes_lastOpenedAppVersionKey"
    
    ///Shared instance
    static public let shared: AUReleaseNotesManager = {
        return AUReleaseNotesManager()
    }()
    
    private init() {
        
    }
    
    ///Determines if this is the first time the user opens the app since the last update
    ///
    ///- important: Only call this methods once in the whole program and save its value through the session. If you call it multiple times, this method will return `false` every time but the first time.
    ///- parameter valueForFirstTimeEver: Value to return if this is the first time ever that the app is openned on the curren device
    public func isFirstOpenning(valueForFirstTimeEver:Bool) -> Bool {
        if let version = UserDefaults.standard.string(forKey: self.lastOpenedAppVersionKey) {
            let lastVersion = try! ProgramVersion(version: version)
            self.saveVersion()
            return lastVersion < Host.currentVersion
        } else {
//            If it doesn't exist, it means that this is the first time the app is opened. 
            self.saveVersion()
            return valueForFirstTimeEver
        }
    }
    
    ///Save the current version
    func saveVersion() {
        UserDefaults.standard.set(Host.currentVersion.description, forKey: self.lastOpenedAppVersionKey)
        UserDefaults.standard.synchronize()
    }
}

/**
 A view which presents the content of a RTF release notes file (RTF = Rich Text File)
 
 - Note: Call ````
 */
public class AUReleaseNotesView: NSView {
    
    ///The scroll view containing the `NSTextView`
    private var textView: NSScrollView
    
    ///The `URL` to the file containing the release notes.
    ///- important: The file must be a valid .rtf file
    private var releaseNotesURL: URL
    
    /// Instanciate a new release note view from an `URL` pointing to the release notes file
    ///
    /// - important: The file containing the release notes must be a valid .rtf file. The content of this file will be shown to the user without any modification
    /// - Parameters:
    ///   - frameRect: Frame of the view
    ///   - releasNotesURL: `URL` to an RTF file containing the release notes for the current version and all the previous ones. The `URL` can be remote or local.
    public init(frame frameRect: NSRect, releasNotesURL: URL) {
        self.textView = NSTextView.scrollableTextView()
        self.releaseNotesURL = releasNotesURL
        super.init(frame: frameRect)
        
//        Load the release notes from the file provided by the URL
        let textView = self.textView.documentView as! NSTextView
        textView.isEditable = false
        textView.backgroundColor = .white
        
        Task {
            let localFileURL = (releaseNotesURL.isFileURL) ? releasNotesURL.path : await self.loadRemoteFile(at: releaseNotesURL).path
            textView.readRTFD(fromFile: localFileURL)
        }
        
//        Create the subViews
        self.addViews()
    }
    
    ///Add the content view to this view
    private func addViews() {
//        Add textView
        self.addSubview(self.textView)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        
        self.textView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1.0).isActive = true
        self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0).isActive = true
        self.textView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true
        self.textView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: -1.0).isActive = true
        
    }
    
    ///In case of a remote release notes file, download its content from the URL and returns the URL to the temporary file containing the release notes.
    private func loadRemoteFile(at url: URL) async -> URL {
        do {
            let (data,_) = try await URLSession.shared.data(for:URLRequest(url: url))
            var tempFile = URL(fileURLWithPath: NSTemporaryDirectory())
            tempFile.appendPathComponent("releaseNotes.rtf")
            try data.write(to: tempFile)
            return tempFile
        } catch let e as NSError {
            print("Impossible to load release notes file: \(e)")
        }
        return url
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



/**
 A class which controls the window responsible for presenting the release notes to the user
 
 - important: The release notes must be saved into a RTF file, which location is known at run time.
 */
public class AUReleaseNotesWindowController: NSWindowController, NSWindowDelegate {
    
    ///The release notes window
    public var releaseNotesWindow: AUReleaseNotesWindow
    
    ///Instantiate the class from the URL of the  release notes file.
    ///- Parameters:
    ///   - url: `URL` to an RTF file containing the release notes for the current version and all the previous ones. The `URL` can be remote or local.
    public init(url: URL) {
        self.releaseNotesWindow = AUReleaseNotesWindow(url: url)
        super.init(window: self.releaseNotesWindow)
        
        self.releaseNotesWindow.delegate = self
        self.releaseNotesWindow.create()
        self.releaseNotesWindow.center()
    }
    
    ///Not implemented (i.e. do not put this class in a StoryBoard!!!
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
