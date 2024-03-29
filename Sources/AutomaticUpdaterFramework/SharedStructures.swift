//
//  SharedStructures.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 24.03.24.
//

import Foundation

public struct ProgramVersion: CustomStringConvertible, Codable {
    
    public var description: String {
//        print(self.version, self.subVersion, self.correctionNumber)
        if correctionNumber == 0 {
            return "\(self.version!).\(self.subVersion!)"
        } else {
            return "\(self.version!).\(self.subVersion!).\(self.correctionNumber!)"
        }
    }
    public let version:Int!
    public let subVersion:Int!
    public let correctionNumber:Int!
    
    init(version:String) {
        let numbers = version.split(separator: ".")
        
        if let first = Int(numbers[0]), let second = Int(numbers[1]) {
            self.version = first
            self.subVersion = second
            if(numbers.count == 3) {
                self.correctionNumber = Int(numbers[2])
            } else {
                self.correctionNumber = 0
            }
        } else {
            self.version = 0
            self.subVersion = 0
            self.correctionNumber = 0
            print("Error converting version number")
        }
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        self.init(version: try container.decode(String.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        try container.encode(self.description)
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
    }
    
    static public func > (left: ProgramVersion, right: ProgramVersion) -> Bool {
        if(left.version == right.version) {
            if(left.subVersion == right.subVersion) {
                return left.correctionNumber > right.correctionNumber
            } else {
                return left.subVersion > right.subVersion
            }
        } else {
            return left.version > right.version
        }
    }
    
    static public func < (left: ProgramVersion, right: ProgramVersion) -> Bool {
        return right > left
    }
    
}

struct UpdateResult : Codable {
    let error:ServerError?
    let recommanded: VersionDescription?
    let alternative: VersionDescription?
}
struct ServerError : Codable {
    let message: String
    let code:Int
    let userInfo: [String]?
}
struct VersionDescription: Codable {
    let version: ProgramVersion
    let url: URL
    let bundleIdentifier: String
}

public class Host : NSObject {
//    let link:String = "http://localhost:8888/YoutubePlayer/update.php"
//    let link:String = "https://damienjaccoud.com/YoutubePlayer/update.php"
    static public var configFile:URL?
    
    ///The link to the updater 
    public let link:String = {
        if let val = Host.getConfigKey(key: "HostLink") {
            return val
        } else {
//            Please, set the key `HostLink` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `HostLink` in the config file")
        }
    }()
    
    ///Get the current version
    static var currentVersion:ProgramVersion = {
        let infoVersion:String
        if let val = Host.getConfigKey(key: "Version") {
            infoVersion = val
        } else if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            infoVersion = appVersion
        } else {
    //            Please, set the key `Version` in your config file, as it could not be found in the info.plist file
            fatalError("You must set the key `Version` in the config file")
        }
        return ProgramVersion(version: infoVersion)
    }()
    
    ///The bundle identifier of the application. This corresponds to the app identifier that is used on the server
    static public var bundleIdentifer: String = {
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
//            Have a look at the documentation. You need to provide the URL to a config file
            fatalError("No URL found for config file. Please, set the static variable `Host.configFile` in time to prevent this error")
        }
        return nil
    }
}

