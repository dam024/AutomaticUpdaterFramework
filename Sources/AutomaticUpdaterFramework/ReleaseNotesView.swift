//
//  ReleaseNotesView.swift
//  
//
//  Created by Jaccoud Damien on 30.03.24.
//

import Cocoa

public class AUReleaseNotesManager {
    private let lastOpenedAppVersionKey: String = "AUReleaseNotes_lastOpenedAppVersionKey"
    
    static public let shared: AUReleaseNotesManager = {
        return AUReleaseNotesManager()
    }()
    
    private init() {
        
    }
    
    public func shouldPresentReleaseNotes() -> Bool {
        if let version = UserDefaults.standard.string(forKey: self.lastOpenedAppVersionKey) {
            let lastVersion = try! ProgramVersion(version: version)
            return lastVersion < Host.currentVersion
        } else {
//            If it doesn't exist, it means that this is the first time the app is opened. 
            self.saveVersion()
        }
        return false
    }
    
    func saveVersion() {
        UserDefaults.standard.set(Host.currentVersion.description, forKey: self.lastOpenedAppVersionKey)
        UserDefaults.standard.synchronize()
    }
}

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
    ///   - releasNotesURL: `URL` to an RTF file containing the release notes for the current version and all the previous ones.
    public init(frame frameRect: NSRect, releasNotesURL: URL) {
        self.textView = NSTextView.scrollableTextView()
        self.releaseNotesURL = releasNotesURL
        super.init(frame: frameRect)
        
//        Save the version in order to avoid opening the release notes each time
        AUReleaseNotesManager.shared.saveVersion()
        
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
