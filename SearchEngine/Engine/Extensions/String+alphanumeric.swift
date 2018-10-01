//
//  String+alphanumeric.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/15/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

extension String {
    
    var alphaNumeric: String {
        
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        
    }
}
