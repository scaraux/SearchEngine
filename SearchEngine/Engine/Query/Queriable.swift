//
//  QueryComponent.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol Queriable {
    func getResultsFrom(index: IndexProtocol) -> [QueryResult]?
    func toString() -> String
}

extension Queriable {
    public func convertToQueryResults(postings: [Posting], fromTerm term: String) -> [QueryResult] {
        return postings.map({ QueryResult($0, term: term) })
    }
}
