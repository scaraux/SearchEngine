//
//  KGramIndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol GramIndexProtocol {
    func registerGramsFor(vocabularyType: VocabularyType)
    func getMatchingCandidatesFor(term: String) -> [String]?
}
