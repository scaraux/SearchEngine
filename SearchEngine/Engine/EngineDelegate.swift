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
    func onFoundSpellingCorrections(corrections: [SpellingSuggestion])
}

protocol CreateEnvironmentDelegate: class {
    func onInitializationPhaseChanged(phase: CreateEnvironmentPhase, withTotalCount: Int)
    func onIndexingDocument(withFileName: String, documentNb: Int, totalDocuments: Int)
    func onIndexingGrams(forType: String, typeNb: Int, totalTypes: Int)
}

protocol LoadEnvironmentDelegate: class {
    func onLoadingPhaseChanged(phase: LoadEnvironmentPhase, withTotalCount: Int)
    func onLoadingTypes(forGram: String, gramNb: Int, totalGrams: Int)
}

enum CreateEnvironmentPhase {
    case phaseIndexingDocuments
    case phaseIndexingGrams
    case phaseWritingIndex
    case terminated
}

enum LoadEnvironmentPhase {
    case phaseLoadingGrams
    case terminated
}
