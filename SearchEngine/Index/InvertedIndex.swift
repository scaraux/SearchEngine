//
//  InvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class InvertedIndex : Index {
    
    private var map: [String : [Posting]]
    
    init() {
        self.map = [String: [Posting]]()
    }
    
    func getPostings(term: String) -> [Posting]? {
        return self.map[term]
    }
    
    func getVocabulary() -> [String] {
        return Array(self.map.keys)
    }
    
    func addTerm(term: String, documentId: Int) {
        let p: Posting = Posting(documentId)
        
        if self.map[term] == nil {
            self.map[term] = [Posting]()
        }
        
        if self.map[term]!.last?.documentId != documentId {
            self.map[term]!.append(p)
        }
    }
}
