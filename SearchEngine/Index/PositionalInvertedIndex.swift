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
    
    func getPostingsFor(term: String) -> [Posting]? {
        return self.map[term]
    }
    
    func getResultsFor(term: String) -> [Result]? {
        var results = [Result]()
        if let postings = self.map[term] {
            for p in postings {
                results.append(Result(p))
            }
            return results
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
