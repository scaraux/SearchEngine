//
//  Posting.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Posting {
    
    var documentId: Int = -1
    var positions: [Int]
    var term: String
    var frequency: Int {
        get {
            return positions.count
        }
    }

    init(withDocumentId id: Int, forTerm term: String) {
        self.documentId = id
        self.positions = [Int]()
        self.term = term
    }
    
    func addPosition(_ position: Int) {
        self.positions.append(position)
    }
}
