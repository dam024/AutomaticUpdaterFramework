//
//  UpdaterViewController.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 24.03.24.
//

import Cocoa

public class UpdaterViewController: NSViewController {
    
    ///Text indication for the user to let him know what the progression is
    @IBOutlet weak var progressReporter: NSTextField!
    
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        Updater.shared.delegate = self
    }
    
    public override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.styleMask.remove(.resizable)//Remove the resizable property of the window
        self.view.window?.styleMask.remove(.closable)//Prevent the window to be closed
        self.view.window?.styleMask.remove(.miniaturizable)//Prevent the user to minimize the window
        
        self.progressIndicator.minValue = 0
        self.progressIndicator.maxValue = 1
        
        Updater.shared.update()
    }

    @IBAction func cancel(_ sender: Any) {
        Updater.shared.cancel()
    }
    
}

extension UpdaterViewController : UpdaterDelegate {
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
