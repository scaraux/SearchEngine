//
//  SearchEngineTests.swift
//  SearchEngineTests
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import XCTest
@testable import SearchEngine

class SearchEngineTests: XCTestCase {
    
    var engine: Engine?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        self.engine = Engine()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.engine = nil
    }
    
    func testKGramIndex() {
        KGramIndex.destroy()
        gramsRegistration()
        getMatchingGramsForTerms()
    }
    
    func gramsRegistration() {
        let term = "abricot"
        
        KGramIndex.shared().registerGramsFor(type: term)
        let registeredTerms = KGramIndex.shared().gramIndex
        
        XCTAssertEqual(registeredTerms.count, 22)
        
        XCTAssertTrue(registeredTerms.keys.contains("a"))
        XCTAssertTrue(registeredTerms.keys.contains("b"))
        XCTAssertTrue(registeredTerms.keys.contains("r"))
        XCTAssertTrue(registeredTerms.keys.contains("i"))
        XCTAssertTrue(registeredTerms.keys.contains("c"))
        XCTAssertTrue(registeredTerms.keys.contains("o"))
        XCTAssertTrue(registeredTerms.keys.contains("t"))
        
        XCTAssertTrue(registeredTerms.keys.contains("$a"))
        XCTAssertTrue(registeredTerms.keys.contains("ab"))
        XCTAssertTrue(registeredTerms.keys.contains("br"))
        XCTAssertTrue(registeredTerms.keys.contains("ri"))
        XCTAssertTrue(registeredTerms.keys.contains("ic"))
        XCTAssertTrue(registeredTerms.keys.contains("co"))
        XCTAssertTrue(registeredTerms.keys.contains("ot"))
        XCTAssertTrue(registeredTerms.keys.contains("t$"))
        
        XCTAssertTrue(registeredTerms.keys.contains("$ab"))
        XCTAssertTrue(registeredTerms.keys.contains("abr"))
        XCTAssertTrue(registeredTerms.keys.contains("bri"))
        XCTAssertTrue(registeredTerms.keys.contains("ric"))
        XCTAssertTrue(registeredTerms.keys.contains("ico"))
        XCTAssertTrue(registeredTerms.keys.contains("cot"))
        XCTAssertTrue(registeredTerms.keys.contains("ot$"))
        
        XCTAssertTrue(registeredTerms["cot"]!.contains(term))
    }
    
    func getMatchingGramsForTerms() {
        var grams: [String]?
        
        let term1 = "red*"
        grams = KGramIndex.shared().getMatchingGramsFor(term: term1)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("red"))
        
        let term2 = "*red"
        grams = KGramIndex.shared().getMatchingGramsFor(term: term2)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("red"))
        XCTAssertTrue(grams!.contains("ed$"))
        
        let term3 = "re*ve"
        grams = KGramIndex.shared().getMatchingGramsFor(term: term3)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("ve$"))
        
        let term4 = "red*a*d"
        grams = KGramIndex.shared().getMatchingGramsFor(term: term4)
        XCTAssertEqual(grams!.count, 4)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("red"))
        XCTAssertTrue(grams!.contains("a"))
        XCTAssertTrue(grams!.contains("d$"))
    }
    
    func matchCandidatesForGrams() {
        let term = "re*ve"
        
        
        print(candidates)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
