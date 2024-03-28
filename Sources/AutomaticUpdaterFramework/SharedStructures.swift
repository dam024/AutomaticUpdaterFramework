//
//  SharedStructures.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 24.03.24.
//

import Foundation


/*struct AutoUpaterResult : Codable {
    let error:String!
    let version:String!
    let url:String!
}*/

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
    var link:String {
        get {
            return "http://localhost:8888/AppUpdater/update.php"
        }
    }
    
    ///The key for the environment variable containing the url
    static let urlEnvironmentKey:String = "url"
    
    let mainAppName: String = "Coproman"
    let updaterName: String = "Coproman Updater"
}

