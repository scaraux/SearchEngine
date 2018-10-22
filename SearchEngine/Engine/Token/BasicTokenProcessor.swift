//
//  BasicTokenProcessor.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class BasicTokenProcessor: TokenProcessorProtocol {
    func processToken(token: String) -> String {
        return token.lowercased()
    }    
}
