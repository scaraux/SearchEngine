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

    init(withDocumentId id: Int, withPosition position: Int, forTerm term: String) {
        self.documentId = id
        self.positions = [Int]()
        self.positions.append(position)
        self.term = term
    }
    
    func addPosition(_ position: Int) -> Void {
        self.positions.append(position)
    }
}


