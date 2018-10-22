//
//  IndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol IndexProtocol {
    
    func getQueryResultsFor(stem: String, fromTerm: String) -> [QueryResult]?
    
    func getPostingsFor(stem: String) -> [Posting]?
    
    func getVocabulary() -> [String]
    
    func getKGramIndex() -> GramIndexProtocol
    
    func clear() -> Void
}
