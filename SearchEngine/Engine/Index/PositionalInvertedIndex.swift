//
//  PositionalInvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PositionalInvertedIndex: IndexProtocol {

    private var map: [String : [Posting]]
    public var kGramIndex: KGramIndex
    
    public var count: Int {
        get {
            return self.map.count
        }
    }

    init() {
        self.map = [String: [Posting]]()
        self.map.reserveCapacity(100000)
        self.kGramIndex = KGramIndex()
    }
    
    func getQueryResultsFor(term: String) -> [QueryResult]? {
        if let postings = self.map[term] {
            return postings.map({ QueryResult($0) })
        }
        return nil
    }
    
    func getKGramIndex() -> KGramIndexProtocol {
        return self.kGramIndex
    }
    
    func getVocabulary() -> [String] {
        return Array(self.map.keys)//.sorted(by: <)
    }
    
    func addTerm(_ term: String, withId id: Int, atPosition position: Int) {
        
        if self.map[term] == nil {
            self.map[term] = [Posting]()
        }
        
        self.map[term]!.count


        
        if self.map[term]!.last?.documentId == id {
//            self.map[term]!.last?.addPosition(position)
        }
        else {
            self.map[term]!.append(Posting(withId: id, atPosition: position, forTerm: term))
        }
    }
    
    func clear() -> Void {
        self.map.removeAll()
    }
}
