//
//  PositionalInvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PositionalInvertedIndex: IndexProtocol {
    
    private var i = 0

    public var map: [String : ContiguousArray<Posting>]
    public var kGramIndex: KGramIndex
    
    public var count: Int {
        get {
            return self.map.count
        }
    }

    init() {
        self.map = [String : ContiguousArray<Posting>]()
        self.kGramIndex = KGramIndex()
    }
    
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]? {
        if let postings = self.map[stem] {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
    
    func getKGramIndex() -> KGramIndexProtocol {
        return self.kGramIndex
    }
    
    func getVocabulary() -> [String] {
        return Array(self.map.keys).sorted(by: <)
    }
    
    func addTerm(_ term: String, withId id: Int, atPosition position: Int) {
        
        if self.map[term] == nil {
            self.map[term] = ContiguousArray<Posting>()
        }
        
        if self.map[term]!.last?.documentId == id {
            self.map[term]!.last?.addPosition(position)
        }
        else {
            self.map[term]!.append(Posting(withId: id, atPosition: position, forTerm: term))

        }
    }
    
    func clear() -> Void {
        self.map.removeAll()
    }
}
