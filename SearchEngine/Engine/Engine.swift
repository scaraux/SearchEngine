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
    private var corpus: DocumentCorpusProtocol?
    var delegate: EngineDelegate?
    
    init() {
        self.index = PositionalInvertedIndex()
        self.queryParser = BooleanQueryParser()
    }
    
    func execQuery(queryString: String) -> Void {
        let query: Queriable? = queryParser.parseQuery(query: queryString)

        if var results: [QueryResult] = query?.getResultsFrom(index: self.index) {
            results = attachDocumentsToResults(results: results)
            self.delegate?.onQueryResulted(results: results)
            return
        }
        self.delegate?.onQueryResulted(results: nil)
    }
    
    func initCorpus(withPath path: URL) -> Void {
        self.corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path, fileExtension: "txt")
        self.indexCorpus(self.corpus!)
    }
    
    func getVocabulary() -> [String] {
        return self.index.getVocabulary()
    }
    
    private func indexCorpus(_ corpus: DocumentCorpusProtocol) -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            let start = DispatchTime.now()

            let processor: BasicTokenProcessor = BasicTokenProcessor()
            let documents: [DocumentProtocol] = corpus.getDocuments()
            
            self.index.clear()
            
            DispatchQueue.main.async {
                self.delegate?.onCorpusIndexingStarted(elementsToIndex: documents.count)
            }
            
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
                
                DispatchQueue.main.async {
                    self.delegate?.onCorpusIndexedOneMoreDocument()
                }
            }
            DispatchQueue.main.async {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000
                self.delegate?.onCorpusInitialized(timeElapsed: timeInterval)
            }
        }
    }
    
    private func attachDocumentsToResults(results: [QueryResult]) -> [QueryResult] {
        for queryResult in results {
            queryResult.document = self.corpus?.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
