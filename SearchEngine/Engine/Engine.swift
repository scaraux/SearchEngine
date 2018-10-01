//
//  Engine.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation

class Engine {
    
    private var index: PositionalInvertedIndex
    private var queryParser: BooleanQueryParser
    private var corpus: DocumentCorpus?
    var delegate: EngineDelegate?
    
    init() {
        self.index = PositionalInvertedIndex()
        self.queryParser = BooleanQueryParser()
    }
    
    func execQuery(queryString: String) -> Void {
        let query: QueryComponent? = queryParser.parseQuery(query: queryString)

        if var results: [QueryResult] = query?.getResultsFrom(index: self.index) {
            results = attachDocumentsToResults(results: results)
            self.delegate?.onQueryResulted(results: results)
            return
        }
        self.delegate?.onQueryResulted(results: nil)
    }
    
    func initCorpus(withPath path: URL) -> Void {
        self.corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path, fileExtension: "txt")
        indexCorpus(self.corpus!)
    }
    
    private func indexCorpus(_ corpus: DocumentCorpus) -> Void {
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
                self.index.addTerm(processedToken, withId: doc.documentId, atPosition: tokenPosition)
                KGramIndex.shared().registerGramsFor(type: processedToken)
                tokenPosition += 1
            }
            tokenStream.dispose()
        }
    }
    
    private func attachDocumentsToResults(results: [QueryResult]) -> [QueryResult] {
        for queryResult in results {
            queryResult.document = self.corpus?.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
