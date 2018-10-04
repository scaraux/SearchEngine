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
    private let tagger: NSLinguisticTagger
    private var corpus: DocumentCorpusProtocol?
    private var documents: [DocumentProtocol]?
    var delegate: EngineDelegate?
    
    init() {
        self.index = PositionalInvertedIndex()
        self.queryParser = BooleanQueryParser()
        self.tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
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
        let start = DispatchTime.now()
        
        self.index.clear()


        guard let corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path) else {
            return
        }
        
        self.retrieveDocuments(corpus: corpus) { (documents: [DocumentProtocol]) in
            self.delegate?.onCorpusIndexingStarted(elementsToIndex: documents.count)
            self.indexDocuments(documents: documents, completion: {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime) / 1_000_000_000
                self.delegate?.onCorpusInitialized(timeElapsed: timeInterval)
            })
        }
    }
    
    func getVocabulary() -> [String] {
        return self.index.getVocabulary()
    }
    

    
    private func retrieveDocuments(corpus: DocumentCorpusProtocol, completion: @escaping ([DocumentProtocol]) -> Void) -> Void {
        DispatchQueue.global(qos: .userInteractive).async {
            let docs: [DocumentProtocol] = corpus.getDocuments()
            DispatchQueue.main.async {
                completion(docs)
            }
        }
    }
    
    
    private func indexDocuments(documents: [DocumentProtocol], completion: @escaping () -> Void) -> Void {
        DispatchQueue.global(qos: .userInteractive).async {
            
            var tokenProcessor = AdvancedTokenProcessor()
            
//            var types = Set<String>()

            for document in documents {
                guard let stream = document.getContent() else {
                    fatalError("Error: Cannot create stream for file \(document.documentId)")
                }
                
                let tokenStream: TokenStreamProtocol = EnglishTokenStream(stream)
                
                let tokens = tokenStream.getTokens()
                for position in 0..<tokens.count {
//                    print(tokens[position])
//                    let sanitized = tokenProcessor.processToken(token: tokens[position])
                    self.index.addTerm(tokens[position], withId: document.documentId, atPosition: position)
                }

                DispatchQueue.main.async {
                    self.delegate?.onCorpusIndexedOneMoreDocument()
                }
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func stemWord(word: String) -> String {
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        tagger.string = word
        
        let range = NSRange(location: 0, length: word.utf16.count)
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
            if let lemma = tag?.rawValue {
                return print(lemma)
            }
        }
        return " "
    }
    
    private func attachDocumentsToResults(results: [QueryResult]) -> [QueryResult] {
        for queryResult in results {
            queryResult.document = self.corpus?.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
