//
//  PostingWriterProtocol.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/21/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

protocol PostingWriterProtocol {
    func getBinaryRepresentation<T: FixedWidthInteger>(forPostings postings: [Posting]) -> [T]
}
