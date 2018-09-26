//
//  IndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol Index {
    
    func getPostingsFor(term: String) -> [Posting]?
    
    func getResultsFor(term: String) -> [Result]?
    
    func getVocabulary() -> [String]
    
    func clear() -> Void
}
