//
//  EngineDelegate.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol EngineDelegate {
    func onCorpusInitialized()
    func onQueryResulted(results: [Result]?)
}
