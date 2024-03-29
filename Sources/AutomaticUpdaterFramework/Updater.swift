//
//  Updater.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 26.03.24.
//

import Foundation
import AppKit
import ZIPFoundation

/**
 Installation:
 1. Add in the bundle target of the main app
 2. Add the updater app in the target dependencies of the main app
 2. Remove the sandbox capabilities of the updater app
 3. Add the "App Transport Security" key in the Info.plist file of both the main and updater app
 4. Add network capabilities in the Sandbox capabilities of the main app
 */

public class Updater : Host {
    
    public static var shared: Updater = {
        Updater()
    }()
    
    ///The delegate
    public var delegate:UpdaterDelegate?
    
    ///The installation task which runs in background
    private var installationTask: Task<(), Never>? = nil
    
    ///A list of items that needs to be cleaned
    private var itemsToClean:[String] = []
    
    ///Perform the update
    public func update() {
        self.installationTask = Task {
            await askForUpdate()
        }
    }
    
    ///Cancel the update and close the application
    public func cancel() {
        self.installationTask?.cancel()
        self.clean()
        self.installationTask = nil
        NSApp.terminate(self)
    }
    
    private func askForUpdate() async {
        print(ProcessInfo.processInfo.environment, ProcessInfo.processInfo.arguments)
//        Get the environment variables
        if let path = ProcessInfo.processInfo.environment[Host.urlEnvironmentKey], let url = URL(string: path) {
            await self.download(url: url)
        } else if ProcessInfo.processInfo.arguments.count > 1, let url = URL(string: ProcessInfo.processInfo.arguments[1]) {
            await self.download(url: url)
        } else {
            self.delegate?.error(message: "Impossible to find URL for update")
        }
    }
    
    ///Returns the URL of the host application
    public func getOldVersionURL() -> URL {
        var oldVersion: URL = Bundle.main.bundleURL
        
        oldVersion.deleteLastPathComponent()
        oldVersion.deleteLastPathComponent()
        oldVersion.deleteLastPathComponent()
        return oldVersion
    }
    
    
    private func download(url:URL) async {
        let fileManager = FileManager()
        do {
            
            //                    On récupère le lien de la main app
            let oldVersion:URL = self.getOldVersionURL()
            
            self.delegate?.message(message: "Downloading new version...", percentage: 2.0/6.0)
            //   Download the data
            let (data, _) = try await URLSession.shared.data(for:URLRequest(url: url,cachePolicy: .reloadIgnoringLocalAndRemoteCacheData), delegate: self)
            
            // Prepare all URLs
            var zipFile = URL(fileURLWithPath: NSTemporaryDirectory())//try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//            zipFile.appendPathComponent(Host.bundleIdentifer)
            var unzipDirectory = zipFile
            zipFile.appendPathComponent("YoutubePlayer.zip")
            unzipDirectory.appendPathComponent("YoutubePlayer")
            
#warning("Je pense que ça peut être bien de vider le cache avant de faire le téléchargement...")
#warning("Faire un programme pour préparer les fichiers à update et tester le tout...")
            
            //Write the files
            self.itemsToClean.append(zipFile.path)
            try data.write(to: zipFile)
            
            self.delegate?.message(message: "Uncompressing files...",percentage: 3.0/6.0)
            
            //Unzip
            self.itemsToClean.append(unzipDirectory.path)
            try fileManager.unzipItem(at: zipFile, to: unzipDirectory)
            
            self.delegate?.message(message:"Installing...",percentage: 4.0/6.0)
            
//                Move new version to its destination directory. The destination directory is the application folder
            let destURL = try self.moveNewVersion(unzipDirectory: unzipDirectory)
//            If the old version hasn't been deleted, appends it to the files to be cleaned
            if fileManager.fileExists(atPath: oldVersion.path) {
                self.itemsToClean.append(oldVersion.path)
            }
            
            self.delegate?.message(message: "Cleaning everything ...",percentage: 5.0/6.0)
//                Delete all files which were required for the update
            self.clean()
            
            self.delegate?.message(message: "Installation complete!", percentage: 1.0)
            if let destURL = destURL {
//                    Launch the new version and terminate the updater
                let conf = NSWorkspace.OpenConfiguration()
                conf.activates = true
                let _ = try await NSWorkspace.shared.openApplication(at: destURL, configuration: conf)
                
                await NSApp.terminate(self)
            }
            
            
        } catch let e as NSError {
            print("Error \(e)")
            self.delegate?.error(message: "\(e.localizedDescription). Update cancelled.")
//            self.clean()
        }
    }
    
    
    /// Move the new version of the application to its new location in the /Application folder.
    ///
    /// The input parameter must be the the path to the unziped file. It must contain a .app file, that will be taken as the new version of the application.
    /// - Parameter unzipDirectory: URL of the folder containing the unzipped file.
    /// - Returns: The URL of the new version if it could be moved
    private func moveNewVersion(unzipDirectory: URL) throws -> URL? {
        let fileManager = FileManager()
        
//        Destination URL + URL for the new version in the unzipped folder
        var destURL = try fileManager.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: false)
        var unzipApplication = unzipDirectory
        
//        Content of the unzipped directory
        let content = try fileManager.contentsOfDirectory(atPath: unzipDirectory.path)
        
        //Search for the new version recursively
        if content.count > 0 {
            var appDirectory = ""
            var queue = Queue<String>()
            queue.push(content)
            while !queue.isEmpty {
                let current = queue.pop()!
                let url = unzipDirectory.appending(component: current)

//                If it can directly find the new version, assign it to the appDirectory
                if url.pathExtension == "app" {
                    appDirectory = current
                    break
                } else if url.isDirectory {

                    var subContent = try fileManager.contentsOfDirectory(atPath: url.path)
                    for i in 0..<subContent.count {
                        subContent[i] = "\(current)/\(subContent[i])"
                    }
                    queue.push(subContent)
                }
            }

//            We add to the destination URL only the name of the application, as we will install it to /Applications/<App Name>.app
            destURL.appendPathComponent(unzipApplication.appending(component: appDirectory).lastPathComponent)
//            Here, we add all the subdirectories with the name of the app, because we want direct access to the new version
            unzipApplication.appendPathComponent(appDirectory)
            
//            Move the new version to the /Applications folder
            do {
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                print("Test before delete",unzipApplication,destURL)
                try fileManager.moveItem(at: unzipApplication, to: destURL)
            } catch let e as NSError {
                self.delegate?.error(message: "Error when updating : \(e.localizedDescription)")
                print("Error when updating : \(e.localizedDescription)")
                self.clean()
                return nil
            }
        }
        return destURL
    }
    
    ///Clean all the files used for the update
    ///
    ///This function must be called at the end of the installation process OR in case of an error that forces the installation to stop.
    private func clean() {
        for item in self.itemsToClean {
            do {
                if FileManager().fileExists(atPath: item) {
                    try FileManager().removeItem(atPath: item)
                } else {
                    print("File at path \(item) does not exists")
                }
            } catch let e as NSError {
                print("Impossible to clean file at path \(item)", e)
            }
        }
    }
}

extension Updater : URLSessionDownloadDelegate {
    #warning("Try to fix these methods which doesn't work... They are not called, causing the app to have no progress bar...")
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Finish downloading")
        self.delegate?.finishDownload()
    }
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.delegate?.progress(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    
}

extension URL {
    ///Indicate if the URL points to a directory
    ///
    /// - remark: If you want to have it work, you need to create an URL starting with file://<URL>. Otherwise, it won't work
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    ///Return an URL that is the current URL to which the component was appended.
    public func appending(component: String) -> URL {
        var url = self
        url.appendPathComponent(component)
        return url
    }
}

public protocol UpdaterDelegate {
    func progress(_ sesson: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    
    func finishDownload()
    
    ///Indicate a progression in the installation process
    ///
    ///- parameter message: The description of the current step in the process
    ///- parameter percentage: The progression given as a percentage (so between 0 and 1)
    func message(message:String,percentage: Double)
    
    func error(message: String)
}
