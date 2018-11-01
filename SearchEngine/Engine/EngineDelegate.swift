//
//  EngineDelegate.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol EngineDelegate: class {
    func onEnvironmentLoaded()
    func onEnvironmentLoadingFailed(withError: String)
    func onQueryResulted(results: [QueryResult]?)
}

protocol EngineInitDelegate: class {
    func onEnvironmentDocumentIndexingStarted(documentsToIndex: Int)
    func onEnvironmentGramsIndexingStarted(gramsToIndex: Int)
    func onEnvironmentIndexedDocument(withFileName: String)
    func onEnvironmentIndexedGram(gramNumber: Int)
    func onEnvironmentInitialized(timeElapsed: Double)
}
