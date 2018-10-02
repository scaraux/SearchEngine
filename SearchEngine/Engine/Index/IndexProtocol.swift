//
//  IndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol IndexProtocol {
    
    func getQueryResultsFor(term: String) -> [QueryResult]?
        
    func getVocabulary() -> [String]
    
    func clear() -> Void
}
