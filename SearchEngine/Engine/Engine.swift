//
//  Engine.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Engine {
    
    var index: PositionalInvertedIndex
    var queryParser: BooleanQueryParser
    var delegate: EngineDelegate?
    var corpus: DocumentCorpus?
    
    init() {
        self.index = PositionalInvertedIndex()
        self.queryParser = BooleanQueryParser()
    }
    func initCorpus(withPath path: URL) -> Void {
        self.corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path, fileExtension: "txt")
        indexCorpus(self.corpus!)
    }
    
    func indexCorpus(_ corpus: DocumentCorpus) -> Void {
        let processor: BasicTokenProcessor = BasicTokenProcessor()
        let documents: [Document] = corpus.getDocuments()
        
        self.index.clear()
        
        for doc in documents {
            guard let stream = doc.getContent() else {
                print("Error: Cannot create stream for file \(doc.documentId)")
                continue
            }
            let tokenStream = EnglishTokenStream(stream)
            let tokens = tokenStream.getTokens()
            
            var tokenPosition = 0
            for rawToken in tokens {                
                let processedToken: String = processor.processToken(token: rawToken)
                index.addTerm(processedToken, withId: doc.documentId, atPosition: tokenPosition)
                tokenPosition += 1
            }
            tokenStream.dispose()
        }
    }
    
    func execQuery(queryString: String) -> Void {

        let query: QueryComponent? = queryParser.parseQuery(query: queryString)
        
        if let results: [Result] = query?.getResultsFrom(index: self.index) {
            for result in results {
                result.document = self.corpus!.getDocumentWith(id: result.documentId)!
            }
            self.delegate?.onQueryResulted(results: results)
            return
        }
        self.delegate?.onQueryResulted(results: nil)
    }
}
