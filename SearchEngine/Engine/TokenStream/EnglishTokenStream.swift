//
//  EnglishTokenStream.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/14/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class EnglishTokenStream: TokenStreamProtocol {
    
    var reader: StreamReader?

    init(_ inputStream: StreamReader) {
        self.reader = inputStream
    }
    
    func getTokens() -> [String] {
        var tokens = [String]()
        
        for line in self.reader! {
            for word in line.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                if !word.isEmpty {
                    tokens.append(word)
                }
            }
        }
        return tokens
    }
    
    func dispose() -> Void {
        self.reader?.close()
        self.reader = nil
    }
}
