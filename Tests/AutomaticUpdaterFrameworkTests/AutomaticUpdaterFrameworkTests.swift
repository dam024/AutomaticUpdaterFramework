import XCTest
@testable import AutomaticUpdaterFramework

final class AutomaticUpdaterFrameworkTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
    }
    
    func testVersion() throws {
        
        XCTAssertEqual(try ProgramVersion(version: "1.2").description, "1.2")
        XCTAssertEqual(try ProgramVersion(version: "1.0").description, "1.0")
        XCTAssertEqual(try ProgramVersion(version: "1.2.3").description, "1.2.3")
        XCTAssertEqual(try ProgramVersion(version: "1.2#2").description, "1.2#2")
        XCTAssertEqual(try ProgramVersion(version: "5.3#45").description, "5.3#45")
        XCTAssertThrowsError(try ProgramVersion(version: "5.34#34#43"))
        
        var v:[ProgramVersion] = []
        v.append(try ProgramVersion(version: "1.0"))
        v.append(try ProgramVersion(version: "1.0#1"))
        v.append(try ProgramVersion(version: "1.0#2"))
        v.append(try ProgramVersion(version: "1.1"))
        v.append(try ProgramVersion(version: "1.1#2"))
        v.append(try ProgramVersion(version: "1.1.1"))
        v.append(try ProgramVersion(version: "2.0"))
        v.append(try ProgramVersion(version: "2.0#1"))
        
        XCTAssertTrue(v[1] < v[3])
        
        for i in 0..<v.count {
            for j in i+1..<v.count {
                XCTAssertTrue(v[i] < v[j], "Comparing \(v[i]) < \(v[j])")
            }
        }
        
//        Other way around
        for i in 0..<v.count {
            for j in 0..<i {
                XCTAssertTrue(v[i] > v[j], "Comparing \(v[i]) > \(v[j])")
            }
        }
    }
}
