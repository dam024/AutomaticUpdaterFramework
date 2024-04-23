//
//  SharedStructures.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 24.03.24.
//

import Foundation

public struct ProgramVersion: CustomStringConvertible, Codable, Equatable {
    
    public var description: String {
//        print(self.version, self.subVersion, self.correctionNumber)
//        if correctionNumber == 0 {
//            return "\(self.version!).\(self.subVersion!)"
//        } else {
//            return "\(self.version!).\(self.subVersion!).\(self.correctionNumber!)"
//        }
        var desc = self.version.map { int in
            "\(int)"
        }.joined(separator: ".")
        if let build = self.build {
            desc += "#\(build)"
        }
        return desc
    }
    
    public var userDescription: String {
        var desc = self.version.map { int in
            "\(int)"
        }.joined(separator: ".")
        if let build = self.build {
            desc += " build \(build)"
        }
        return desc
    }
    
    ///Version
    public let version:[Int]
    ///Build number of the version
    public let build:Int?
    
    init(version:String) throws {
        let numbers = version.split(separator: "#")
        var array:[Int] = []
        
        if numbers.count > 2 || numbers.count == 0{
            throw NSError(domain: "Invalid version string", code: 20)
        }
        
        if numbers.count == 2 {
            self.build = Int(numbers[1])
        } else {
            self.build = nil
        }
        
        let splittedElements = numbers[0].split(separator: ".")
        for v in splittedElements {
            if let i = Int(v) {
                array.append(i)
            }
        }
        self.version = array
    }
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            try self.init(version: try container.decode(String.self))
        } else {
            let container = try decoder.container(keyedBy: CodingKeyProtocol.self)
            
            var v = try container.decode(String.self, forKey: CodingKeyProtocol.versionKey)
            if let build = try? container.decode(Int.self, forKey: CodingKeyProtocol.buildKey) {
                v += "#\(build)"
            }
            try self.init(version: v)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeyProtocol.self)
        
        try container.encode(self.version.map({ int in
            "\(int)"
        }).joined(separator: "."), forKey: CodingKeyProtocol.versionKey)
        if let build = self.build {
            try container.encode(build, forKey: CodingKeyProtocol.buildKey)
        }
    }
    
    private struct CodingKeyProtocol: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
        
        static let versionKey = CodingKeyProtocol(stringValue: "version")!
        static let buildKey = CodingKeyProtocol(stringValue: "build")!
    }
    
    static public func > (left: ProgramVersion, right: ProgramVersion) -> Bool {
        for i in 0..<min(left.version.count, right.version.count) {
            if left.version[i] != right.version[i] {
                return left.version[i] > right.version[i]
            }
        }
        if left.version.count < right.version.count {
            return false
        } else if left.version.count == right.version.count {
            if left.build == nil && right.build == nil {
                return false
            }
            return (left.build ?? 0 > right.build ?? 0)
        }
        return true
    }
    
    static public func < (left: ProgramVersion, right: ProgramVersion) -> Bool {
        return right > left
    }
    
}

struct UpdateResult : Codable, Equatable {
    let error:ServerError?
    let recommanded: VersionDescription?
    let alternative: VersionDescription?
}
struct ServerError : Codable, Equatable {
    let message: String
    let code:Int
    let userInfo: [String]?
}
struct VersionDescription: Codable, Equatable {
    let version: ProgramVersion
    let url: URL
    let bundleIdentifier: String
    
    init(version: ProgramVersion, url: URL, bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
        self.url = url
        self.version = version
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let version = try container.decode(String.self, forKey: .version)
        let build = try container.decode(String?.self, forKey: .build)
        let url = try container.decode(URL.self, forKey: .url)
        let bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        
        let versionString = (build != nil) ? "\(version)#\(build!)" : version
        let programVersion = try ProgramVersion(version: versionString)
        
        self.init(version: programVersion, url: url, bundleIdentifier: bundleIdentifier)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.version.version.map{ String($0) }.joined(separator:"."), forKey: .version)
        let build = (self.version.build != nil) ? "\(self.version.build!)" : nil
        try container.encode(build, forKey: .build)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.bundleIdentifier, forKey: .bundleIdentifier)
    }
    
    private struct CodingKeys: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return nil
        }
        static let version: CodingKeys = .init(stringValue: "version")!
        static let build: CodingKeys = .init(stringValue: "build")!
        static let url: CodingKeys = .init(stringValue: "url")!
        static let bundleIdentifier: CodingKeys = .init(stringValue: "bundleIdentifier")!
    }
}

public class Host : NSObject {
//    let link:String = "http://localhost:8888/YoutubePlayer/update.php"
//    let link:String = "https://damienjaccoud.com/YoutubePlayer/update.php"
    static public var configFile:URL?
    
    ///The link to the updater 
    public static let link:String = {
        if let val = Host.getConfigKey(key: "HostLink") {
            return val
        } else {
//            Please, set the key `HostLink` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `HostLink` in the config file")
        }
    }()
    
    ///Get the current version
    static let currentVersion:ProgramVersion = {
        var infoVersion:String
        if let val = Host.getConfigKey(key: "Version") {
            infoVersion = val
        } else if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            infoVersion = appVersion
        } else {
    //            Please, set the key `Version` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `Version` in the config file")
        }

        return try! ProgramVersion(version: infoVersion)
    }()
    
    static let currentBuild:Int? = {
//        Add build number
        if let val = Int(Host.getConfigKey(key: "Build") ?? "") {
            return val
        } else if let appVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? Int {
            return appVersion
        }
        return nil
    }()
    
    ///The bundle identifier of the application. This corresponds to the app identifier that is used on the server
    static public let bundleIdentifer: String = {
        if let val = Host.getConfigKey(key: "Identifier") {
            return val
        } else if let appIdentifier  = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            return appIdentifier
        } else {
//            Please, set the key `Identifier` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `Identifier` in the config file")
        }
    }()
    
    ///The key for the environment variable containing the url
    static public let urlEnvironmentKey:String = "url"
    
    static public let mainAppName: String = {
        if let val = Host.getConfigKey(key: "mainAppName") {
            return val
        } else if let appName  = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String {
            return appName
        } else {
//            Please, set the key `mainAppName` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `mainAppName` in the config file")
        }
    }()
    static public let updaterName: String = {
        if let val = Host.getConfigKey(key: "updaterName") {
            return val
        } else {
//            Please, set the key `updaterName` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `updaterName` in the config file")
        }
    }()
    
    class func getConfigKey(key:String) -> String? {
        if let url = self.configFile {
            let data = try! Data(contentsOf: url)
            
            do {
                let result = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String:String]
                return result[key]
            } catch let e as NSError {
//                The config file must use a valid Property List file format. Create a file with extension .plist
                fatalError("Incorrect config file format: \(e.localizedDescription). Please, use a property list file (.plist)")
            }
            
        } else {
//            Have a look at the documentation. You need to provide the URL to a config file.
            fatalError("No URL found for config file. Please, set the static variable `Host.configFile` in time to prevent this error")
        }
        return nil
    }
}

