//
//  PositionalInvertedIndex.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PositionalInvertedIndex: IndexProtocol {

    private(set) var map: [String: [Posting]]
    private(set) var types: [String: String]
    private(set) var kGramIndex: GramIndex
    private var elements: Set<VocabularyElement>

    init() {
        self.map = [:]
        self.types = [:]
        self.kGramIndex = GramIndex()
        self.elements = Set<VocabularyElement>()
    }
    
    init(withIndex index: [String: [Posting]]) {
        self.map = index
        self.types = [:]
        self.kGramIndex = GramIndex()
        self.elements = Set<VocabularyElement>()
    }

    private func withPostings<R>(forStem stem: String, mutations: (inout [Posting]) throws -> R) rethrows -> R {
        return try mutations(&map[stem, default: []])
    }

    func getPostingsWithoutPositionsFor(stem: String) -> [Posting]? {
        return self.map[stem]
    }
    
    func getPostingsWithPositionsFor(stem: String) -> [Posting]? {
        return self.map[stem]
    }
    
    func getWeightForDocument(documentId: Int) -> Double? {
        return nil
    }
    
    public func getKGramIndex() -> GramIndexProtocol {
        return self.kGramIndex
    }
    
    public func getVocabulary() -> [String] {
        return Array(self.map.keys).sorted(by: <)
    }
    
    func getElements() -> Set<VocabularyElement> {
        return self.elements
    }

    public func addElement(_ element: VocabularyElement, withDocumentId docId: Int, atPosition position: Int) {
        withPostings(forStem: element.stem) { postings in
            if let posting = postings.last, posting.documentId == docId {
                posting.addPosition(position)
            }
            else {
                let posting = Posting(withDocumentId: docId, forTerm: element.stem)
                posting.addPosition(position)
                postings.append(posting)                
            }
        }
        self.types[element.type] = element.stem
        self.elements.insert(element)
    }
    
    func dispose() {
        
    }
}

extension PositionalInvertedIndex {
    
    public func getQueryResultsFor(stem: String, fromTerm: String,
                                   withDummyMap map: [String: [Posting]]) -> [QueryResult]? {
        if let postings = map[stem] {
            return postings.map({ QueryResult($0, term: fromTerm) })
        }
        return nil
    }
}
