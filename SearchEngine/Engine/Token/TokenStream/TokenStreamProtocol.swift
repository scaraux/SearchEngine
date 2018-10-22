//
//  TokenStreamProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol TokenStreamProtocol {
    func getTokens() -> [String]
    func dispose()
}
