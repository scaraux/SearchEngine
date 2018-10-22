//
//  DiskWritingTests.swift
//  SearchEngineTests
//
//  Created by Oscar Götting on 10/21/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//
// swiftlint:disable function_body_length identifier_name

import XCTest
@testable import SearchEngine

class DiskWritingTests: XCTestCase {
    
    var map: [String: [Posting]] = [:]

    override func setUp() {
        super.setUp()

        // TERM 1--
        let term1 = "abricot"
        // TERM 2--
        let term2 = "benedict"
        // TERM 3--
        let term3 = "the"
        
        // INITIALIZE MAP
        map[term1] = []
        map[term2] = []
        map[term3] = []
        
        // TERM 1-- POSTING 1--
        let _t1p1 = Posting(withDocumentId: 1, withPosition: 42, forTerm: term1)
        _t1p1.addPosition(54)
        _t1p1.addPosition(62)
        _t1p1.addPosition(74)
        _t1p1.addPosition(212)
        
        // TERM 1-- POSTING 2--
        let _t1p2 = Posting(withDocumentId: 6, withPosition: 7, forTerm: term1)
        _t1p2.addPosition(14)
        _t1p2.addPosition(36)
        
        // TERM 1-- POSTING 3--
        let _t1p3 = Posting(withDocumentId: 6, withPosition: 7, forTerm: term1)
        _t1p3.addPosition(14)
        _t1p3.addPosition(36)
        
        // TERM 2-- POSTING 1--
        let _t2p1 = Posting(withDocumentId: 1, withPosition: 4, forTerm: term2)
        _t2p1.addPosition(54)
        _t2p1.addPosition(62)
        _t2p1.addPosition(74)
        _t2p1.addPosition(212)
        
        // TERM 2-- POSTING 2--
        let _t2p2 = Posting(withDocumentId: 15, withPosition: 314, forTerm: term2)
        
        // TERM 3-- POSTING 1--
        let _t3p1 = Posting(withDocumentId: 1, withPosition: 4, forTerm: term3)
        _t3p1.addPosition(14)
        _t3p1.addPosition(19)
        _t3p1.addPosition(34)
        _t3p1.addPosition(62)
        // TERM 3-- POSTING 2--
        let _t3p2 = Posting(withDocumentId: 2, withPosition: 8, forTerm: term3)
        _t3p2.addPosition(17)
        _t3p2.addPosition(84)
        _t3p2.addPosition(104)
        // TERM 3-- POSTING 3--
        let _t3p3 = Posting(withDocumentId: 3, withPosition: 1, forTerm: term3)
        _t3p3.addPosition(19)
        _t3p3.addPosition(34)
        _t3p3.addPosition(50)
        
        map[term1]?.append(_t1p1)
        map[term1]?.append(_t1p2)
        map[term1]?.append(_t1p3)
        map[term2]?.append(_t2p1)
        map[term2]?.append(_t2p2)
        map[term3]?.append(_t3p1)
        map[term3]?.append(_t3p2)
        map[term3]?.append(_t3p3)
    }

    override func tearDown() {
    
    }

    func testWriteIndex() {
        let index: IndexProtocol = PositionalInvertedIndex(withIndex: self.map)
        let writer: DiskIndexWriter = DiskIndexWriter()
        
        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        let desktopDir = paths[0]
        
        writer.writeIndex(index: index, atPath: desktopDir)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
