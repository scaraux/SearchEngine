//
//  PositionalInvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PositionalInvertedIndex: Index {
    
    private var map: [String : [Posting]]

    init() {
        self.map = [String: [Posting]]()
    }
    
    func getQueryResultsFor(term: String) -> [QueryResult]? {
        if let postings = self.map[term] {
            return postings.map({ QueryResult($0) })
        }
        return nil
    }
    
    func getVocabulary() -> [String] {
        return Array(self.map.keys)
    }
    
    func addTerm(_ term: String, withId id: Int, atPosition position: Int) {
        let posting: Posting = Posting(withId: id, atPosition: position, forTerm: term)

        if self.map[term] == nil {
            self.map[term] = [Posting]()
        }

        if self.map[term]!.last?.documentId == id {
            self.map[term]!.last?.addPosition(position)
        }
        else {
            self.map[term]!.append(posting)
        }
    }
    
    func clear() -> Void {
        self.map.removeAll()
    }
}
