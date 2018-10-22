//
//  PostingWriter.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/21/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class PostingWriter: PostingWriterProtocol {
    
    func getBinaryRepresentation<T: FixedWidthInteger>(forPostings postings: [Posting]) -> [T] {
        var representation = [T]()
        let dft: T = T(postings.count)
        
        representation.append(dft.bigEndian)
        
        for posting in postings {
            let id: T = T(posting.documentId)
            let tftd: T = T(posting.positions.count)
            
            representation.append(id.bigEndian)
            representation.append(tftd.bigEndian)
            
            for position in posting.positions {
                let position: T = T(position)
                representation.append(position.bigEndian)
            }
        }
        return representation
    }
}
