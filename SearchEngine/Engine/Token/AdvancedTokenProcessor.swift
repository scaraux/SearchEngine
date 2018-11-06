//
//  AdvancedTokenProcessor.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/2/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class AdvancedTokenProcessor: TokenProcessorProtocol {
    func processToken(token: String) -> String {
        var result = String()
        for ascii in token.utf8 {
            if ascii > 47 && ascii < 58 {
                result.append(String(UnicodeScalar(UInt8(ascii))))
            } else if ascii > 64 && ascii < 91 {
                result.append(String(UnicodeScalar(UInt8(ascii + 32))))
            } else if ascii > 96 && ascii < 123 {
                result.append(String(UnicodeScalar(UInt8(ascii))))
            }
        }
        return result
    }
}
