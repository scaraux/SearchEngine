//
//  Posting.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Posting {
    
    private(set) var documentId: Int = -1
    private(set) var positions: [Int]
    private(set) var term: String
    var wdt: Double = 0.0
    var frequency: Int {
        return positions.count
    }

    init(withDocumentId id: Int, forTerm term: String = "") {
        self.documentId = id
        self.positions = [Int]()
        self.term = term
    }
    
    func addPosition(_ position: Int) {
        self.positions.append(position)
    }
    
    func calculateWdt() -> Double {
        return 1 + log(Double(positions.count))
    }
}
