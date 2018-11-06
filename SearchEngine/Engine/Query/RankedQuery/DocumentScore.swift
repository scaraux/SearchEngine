//
//  Accumulator.swift
//  SearchEngine
//
//  Created by Oscar Götting on 11/5/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class DocumentScore: Comparable {
    
    private(set) var documentId: Int
    private(set) var matchingTerms: [String] = []
    var score: Double = 0.0
    var accumulator: Double = 0.0
    
    init(documentId id: Int) {
        self.documentId = id
    }
    
    public func addMatchingTerm(term: String) {
        self.matchingTerms.append(term)
    }
    
    static func < (lhs: DocumentScore, rhs: DocumentScore) -> Bool {
        return lhs.score < rhs.score
    }
    
    static func == (lhs: DocumentScore, rhs: DocumentScore) -> Bool {
        return lhs.score == rhs.score
    }
}
