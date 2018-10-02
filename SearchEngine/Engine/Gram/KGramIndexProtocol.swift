//
//  KGramIndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol KGramIndexProtocol {
    func registerGramsFor(type: String) -> Void
    func getMatchingCandidatesFor(term: String) -> [String]?
    
}
