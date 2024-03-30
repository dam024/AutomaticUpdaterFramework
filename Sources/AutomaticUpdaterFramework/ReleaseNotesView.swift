//
//  ReleaseNotesView.swift
//  
//
//  Created by Jaccoud Damien on 30.03.24.
//

import Cocoa

public class AUReleaseNotesView: NSView {
    
    private var textView: NSScrollView
    
//    private var cancelButton: NSButton!
    
    private var releaseNotesURL: URL
    
    public init(frame frameRect: NSRect, releasNotesURL: URL) {
        self.textView = NSTextView.scrollableTextView()//scrollableDocumentContentTextView()
        self.releaseNotesURL = releasNotesURL
        super.init(frame: frameRect)
        
//        self.cancelButton = NSButton(image: .init(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Cross button to close the window")!, target: self, action: #selector(self.cancel(_:)))
        
//        self.cancelButton.bezelStyle = .inline
//        let attributedString: NSAttributedString = try NSAttributedString(url: releasNotesURL, options: [.documentType:NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        
        let textView = self.textView.documentView as! NSTextView
//        textView.isRichText = true
        textView.isEditable = false
        textView.backgroundColor = .white
        print("Test add",textView.readRTFD(fromFile: releasNotesURL.path))
        
        self.addViews()
        
    }
    
    private func addViews() {
//        Add cancel button
        /*self.addSubview(self.cancelButton)
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.cancelButton.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0).isActive = true
        self.cancelButton.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true*/
        
//        Add textView
        self.addSubview(self.textView)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        
        self.textView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1.0).isActive = true
//        self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.cancelButton.bottomAnchor, multiplier: 1.0).isActive = true
        self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0).isActive = true
        self.textView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.trailingAnchor, multiplier: -1.0).isActive = true
        self.textView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bottomAnchor, multiplier: -1.0).isActive = true
        
    }
    
    @objc private func cancel(_ sender: Any?) {
        self.window?.close()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}