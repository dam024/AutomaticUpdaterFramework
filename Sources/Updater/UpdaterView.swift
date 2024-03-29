//
//  File.swift
//  
//
//  Created by Jaccoud Damien on 29.03.24.
//

import Cocoa
import AutomaticUpdaterFramework

class UpdaterView : NSView {
    
    ///Text indication for the user to let him know what the progression is
    var progressReporter:NSTextField
    
    ///Progress indicator to show what is left
    var progressIndicator: NSProgressIndicator
    
    ///The cancel button
    var cancelButton: NSButton!
    
    override init(frame: NSRect) {
//        Initialize the view
        self.progressReporter = NSTextField(wrappingLabelWithString: "Installing update")//NSTextField(string: "Installing update")
        self.progressIndicator = NSProgressIndicator()
        super.init(frame: frame)
        
        self.cancelButton = NSButton(title: "Cancel", target: self, action: #selector(self.cancel(_:)))
        
//        Add the views to the view hierarchy
        self.addSubview(self.progressReporter)
        self.addSubview(self.progressIndicator)
        self.addSubview(self.cancelButton)
        
//        Config the views
        self.configViews()
        
//        Add the constraints on the interface
        self.addConstraints()
        
//        Set to updater delegate
        Updater.shared.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
//        print("Drawing the view")
    }
    
    private func configViews() {
        self.progressIndicator.minValue = 0
        self.progressIndicator.maxValue = 1
    }
    
    private func addConstraints() {
        
//        Progress reporter - label
        self.progressReporter.translatesAutoresizingMaskIntoConstraints = false
        
        self.progressReporter.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1.0).isActive = true
        self.progressReporter.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0).isActive = true
        self.progressReporter.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true
        
//        Progress indicator
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        self.progressIndicator.topAnchor.constraint(equalToSystemSpacingBelow: self.progressReporter.bottomAnchor, multiplier: 2.0).isActive = true
        self.progressIndicator.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1.0).isActive = true
        self.progressIndicator.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true
        self.progressIndicator.widthAnchor.constraint(equalToConstant: 400).isActive = true
        
//        Cancel button
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.cancelButton.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: -1.0).isActive = true
        self.cancelButton.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true
        self.cancelButton.topAnchor.constraint(equalToSystemSpacingBelow: self.progressIndicator.bottomAnchor, multiplier: 1.0).isActive = true
    }
    
    @objc func cancel(_ sender: Any?) {
        Updater.shared.cancel()
    }
}

extension UpdaterView: UpdaterDelegate {
    public func error(message: String) {
        DispatchQueue.main.async {
            self.progressReporter.stringValue = message
            self.progressReporter.textColor = .red
        }
    }
    
    public func progress(_ sesson: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let conversionFactor:Int64 = 1024
        print(bytesWritten)
        
        DispatchQueue.main.async {
            self.progressReporter.stringValue = "\(totalBytesWritten/conversionFactor) kB downloaded on \(totalBytesExpectedToWrite/conversionFactor) kB (\(totalBytesWritten/totalBytesExpectedToWrite)%)"
            self.progressIndicator.doubleValue = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
    
    public func finishDownload() {
        print("Download done...")
    }
    
    public func message(message: String, percentage: Double) {
        DispatchQueue.main.async {
            self.progressReporter.stringValue = message
            self.progressIndicator.doubleValue = percentage
        }
    }
}
