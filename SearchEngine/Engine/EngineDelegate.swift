//
//  EngineDelegate.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol EngineDelegate: class {
    func onQueryResulted(results: [QueryResult]?)
}

protocol EngineInitDelegate: class {
    func onCorpusDocumentIndexingStarted(documentsToIndex: Int)
    func onCorpusGramsIndexingStarted(gramsToIndex: Int)
    func onCorpusIndexedDocument(withFileName: String)
    func onCorpusIndexedGram(gramNumber: Int)
    func onCorpusInitialized(timeElapsed: Double)
}
