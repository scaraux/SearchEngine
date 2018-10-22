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
        super.setUp()
        self.engine = Engine()
    }
    
    override func tearDown() {
        super.tearDown()
        self.engine = nil
    }
    
    func testBooleanQueryParser() {
        let parser = BooleanQueryParser()
        var result: Queriable
        
        let andQuery = "whale ships"
        result = parser.parseQuery(query: andQuery)!
        XCTAssertTrue(result is AndQuery)
        
        let orQuery = "whale + ships"
        result = parser.parseQuery(query: orQuery)!
        XCTAssertTrue(result is OrQuery)

        let phraseLiteralQuery = "\"whale ships\""
        result = parser.parseQuery(query: phraseLiteralQuery)!
        XCTAssertTrue(result is PhraseLiteral)

        let wildCardQuery = "wh*e"
        result = parser.parseQuery(query: wildCardQuery)!
        XCTAssertTrue(result is WildcardLiteral)

        let combinedQuery = "whale + boat cruise"
        result = parser.parseQuery(query: combinedQuery)!
        XCTAssertTrue(result is OrQuery)
        var rightPartOfOr = (result as! OrQuery).components[1]
        XCTAssertTrue(rightPartOfOr is AndQuery)
        XCTAssertTrue((rightPartOfOr as! AndQuery).components.count == 2)

        let complexQuery = "whale + \"is here\" an* sees"
        result = parser.parseQuery(query: complexQuery)!
        XCTAssertTrue(result is OrQuery)
        rightPartOfOr = (result as! OrQuery).components[1]
        XCTAssertTrue(rightPartOfOr is AndQuery)
        let leftPartOfAnd = (rightPartOfOr as! AndQuery).components[0]
        XCTAssertTrue(leftPartOfAnd is PhraseLiteral)
        let middlePartOfAnd = (rightPartOfOr as! AndQuery).components[1]
        XCTAssertTrue(middlePartOfAnd is WildcardLiteral)
        let lastPartOfAnd = (rightPartOfOr as! AndQuery).components.last!
        XCTAssertTrue(lastPartOfAnd is TermLiteral)
    }
    
    func testKGramIndex() {
        let index = GramIndex()
        gramsRegistration(index: index)
        getMatchingGramsForTerms(index: index)
    }
    
    func gramsRegistration(index: GramIndex) {
        let term = "abricot"

        index.registerGramsFor(type: term)
        let registeredTerms = index.map

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
    
    func getMatchingGramsForTerms(index: GramIndex) {
        var grams: [String]?
        
        let term1 = "red*"
        grams = index.getMatchingGramsFor(term: term1)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("red"))
        
        let term2 = "*red"
        grams = index.getMatchingGramsFor(term: term2)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("red"))
        XCTAssertTrue(grams!.contains("ed$"))
        
        let term3 = "re*ve"
        grams = index.getMatchingGramsFor(term: term3)
        XCTAssertEqual(grams!.count, 2)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("ve$"))
        
        let term4 = "red*a*d"
        grams = index.getMatchingGramsFor(term: term4)
        XCTAssertEqual(grams!.count, 4)
        XCTAssertTrue(grams!.contains("$re"))
        XCTAssertTrue(grams!.contains("red"))
        XCTAssertTrue(grams!.contains("a"))
        XCTAssertTrue(grams!.contains("d$"))
    }
}
