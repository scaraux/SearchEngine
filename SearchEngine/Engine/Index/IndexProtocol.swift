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
        
    func getVocabulary() -> [String]
    
    func getKGramIndex() -> KGramIndexProtocol
    
    func clear() -> Void
}
