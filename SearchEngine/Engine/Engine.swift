//
//  Engine.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

class Engine {
    
    private var index: PositionalInvertedIndex
    private var indexWriter: DiskIndexWriter
    private var queryParser: BooleanQueryParser
    private let stemmer: PorterStemmer
    private var corpus: DocumentCorpusProtocol?
//    private var documents: [DocumentProtocol]?
    
    var delegate: EngineDelegate?
    var initDelegate: EngineInitDelegate?
    
    init() {
        self.index = PositionalInvertedIndex()
        self.indexWriter = DiskIndexWriter()
        self.queryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
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
    
    func getVocabulary() -> [String] {
        return self.index.getVocabulary()
    }
    
    func stemWord(word: String) -> String {
        return self.stemmer.stem(word)
    }
    
    func initCorpus(withPath path: URL) -> Void {
        let start = DispatchTime.now()
        
        self.index.clear()

        guard let corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: path) else {
            return
        }
        
        self.retrieveDocuments(corpus: corpus) { (documents: [DocumentProtocol]) in
            self.initDelegate?.onCorpusDocumentIndexingStarted(documentsToIndex: documents.count)
            self.indexDocuments(documents: documents, completion: {
                
                self.corpus = corpus
                self.initDelegate?.onCorpusInitialized(timeElapsed: self.calculateElapsedTime(from: start))
                self.indexWriter.writeIndex(index: self.index, atPath: path)
            })
        }
    }
    
    private func calculateElapsedTime(from: DispatchTime) -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - from.uptimeNanoseconds
        return Double(nanoTime) / 1_000_000_000
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
            
            let tokenProcessor = AdvancedTokenProcessor()
            var types = Set<String>()

            for document in documents {
                guard let stream = document.getContent() else {
                    fatalError("Error: Cannot create stream for file \(document.documentId)")
                }
                
                let tokenStream: TokenStreamProtocol = EnglishTokenStream(stream)
                let tokens = tokenStream.getTokens()
                
                for position in 0..<tokens.count {
                    let sanitized = tokenProcessor.processToken(token: tokens[position])
                    types.insert(sanitized)
                    let stemmed = self.stemWord(word: sanitized)
                    self.index.addTerm(stemmed, withId: document.documentId, atPosition: position)
                }
                DispatchQueue.main.async {
                    self.initDelegate?.onCorpusIndexedDocument(withFileName: document.fileName)
                }
            }
            
            var typeNb = 1
            DispatchQueue.main.async {
                self.initDelegate?.onCorpusGramsIndexingStarted(gramsToIndex: types.count)
            }
            
            for type in types {
                self.index.kGramIndex.registerGramsFor(type: type)
                DispatchQueue.main.async {
                    self.initDelegate?.onCorpusIndexedGram(gramNumber: typeNb)
                }
                typeNb += 1
            }
            DispatchQueue.main.async {
                completion()
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
