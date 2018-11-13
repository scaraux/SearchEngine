//
//  KGramIndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol GramIndexProtocol {
    func registerGramsFor(vocabularyElement: VocabularyElement)
    func getSimilarCandidatesFor(term: String) -> [VocabularyElement]?
    func getMatchingCandidatesFor(term: String) -> [VocabularyElement]?
}
