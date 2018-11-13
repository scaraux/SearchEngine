//
//  IndexProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol IndexProtocol {
    func getPostingsWithoutPositionsFor(stem: String) -> [Posting]?
    func getPostingsWithPositionsFor(stem: String) -> [Posting]?
    func getWeightForDocument(documentId: Int) -> Double?
    func getElements() -> Set<VocabularyElement>
    func getVocabulary() -> [String]
    func getKGramIndex() -> GramIndexProtocol
    func dispose()
}
