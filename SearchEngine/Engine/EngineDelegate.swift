//
//  EngineDelegate.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol EngineDelegate {
    func onCorpusIndexingStarted(elementsToIndex: Int)
    func onCorpusIndexedOneMoreDocument()
    func onCorpusInitialized(timeElapsed: Double)
    func onCorpusIndexedGram(gramNb: Int, totalGrams: Int)
    func onQueryResulted(results: [QueryResult]?)
}
