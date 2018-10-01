//
//  QueryComponent.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/16/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol QueryComponent {
    
    func getResultsFrom(index: Index) -> [QueryResult]?
    
    func toString() -> String
    
}
