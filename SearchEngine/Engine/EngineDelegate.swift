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
    func onInitializationPhaseChanged(phase: InitPhase, withTotalCount: Int)
    
    func onIndexingDocument(withFileName: String, documentNb: Int, totalDocuments: Int)
    
    func onIndexingGrams(forType: String, typeNb: Int, totalTypes: Int)
}

enum InitPhase {
    case phaseIndexingDocuments
    case phaseIndexingGrams
    case phaseWritingIndex
    case terminated
}
