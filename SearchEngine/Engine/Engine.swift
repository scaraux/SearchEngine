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
    private var queryParser: BooleanQueryParser
    private let stemmer: PorterStemmer
    private var corpus: DocumentCorpusProtocol?
    private var index: IndexProtocol?

    weak var delegate: EngineDelegate?
    weak var initDelegate: EngineInitDelegate?
    
    init() {
        self.queryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
    }
    
    func execQuery(queryString: String) {
        guard let index = self.index else {
            print("No environment selected !")
            return
        }
        let query: Queriable? = queryParser.parseQuery(query: queryString)
        if var results: [QueryResult] = query?.getResultsFrom(index: index) {
            results = attachDocumentsToResults(results: results)
            self.delegate?.onQueryResulted(results: results)
            return
        }
        self.delegate?.onQueryResulted(results: nil)
    }
    
    func getVocabulary() -> [String] {
        guard let index = self.index else {
            print("No environment selected !")
            return []
        }
       return index.getVocabulary()
    }
    
    func stemWord(word: String) -> String {
        return self.stemmer.stem(word)
    }
    
    func loadEnvironment(withPath url: URL) {
        
        guard let corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: url) else {
            return
        }
        
        self.corpus = corpus
        self.corpus!.readDocuments()

        do {
            let utility = try DiskIndexUtility(atPath: url,
                                               fileMode: .reading,
                                               postingsEncoding: UInt32.self,
                                               offsetsEncoding: UInt64.self)
            
            self.index = DiskPositionalIndex(atPath: url, utility: utility)
            self.delegate?.onEnvironmentLoaded()
            
        } catch let error as NSError {
            self.delegate?.onEnvironmentLoadingFailed(withError: error.localizedFailureReason!)
        }
    }
    
    func newEnvironment(withPath url: URL) {
        // Snapshot start time
        let start = DispatchTime.now()
        // Load corpus
        guard let corpus = DirectoryCorpus.loadDirectoryCorpus(absolutePath: url) else {
            return
        }
        // Retrieve all documents in corpus asynchronously
        self.retrieveDocuments(corpus: corpus) { (documents: [DocumentProtocol]) in
            // Notify that indexing started
            self.initDelegate?.onEnvironmentDocumentIndexingStarted(documentsToIndex: documents.count)
            // Generate Positional Inverted Index in memory, asynchronously
            self.generateIndex(documents: documents, { index in
                // Notify that corpus has been initialized
                self.initDelegate?.onEnvironmentInitialized(timeElapsed: self.calculateElapsedTime(from: start))
                // Write index on disk
                self.writeIndexOnDisk(index: index, atUrl: url)
            })
        }
    }
    
    private func writeIndexOnDisk(index: IndexProtocol, atUrl url: URL) {
        do {
            let utility = try DiskIndexUtility(atPath: url,
                                               fileMode: .writing,
                                               postingsEncoding: UInt32.self,
                                               offsetsEncoding: UInt64.self)
            utility.writeIndex(index: index)
            utility.dispose()
        } catch let error as NSError {
            print(error.description)
        }
    }

    private func calculateElapsedTime(from: DispatchTime) -> Double {
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - from.uptimeNanoseconds
        return Double(nanoTime) / 1_000_000_000
    }
    
    private func retrieveDocuments(corpus: DocumentCorpusProtocol,
                                   completion: @escaping ([DocumentProtocol]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let docs: [DocumentProtocol] = corpus.getDocuments()
            DispatchQueue.main.async {
                completion(docs)
            }
        }
    }
    
    private func generateIndex(documents: [DocumentProtocol], _ completion: @escaping (_: IndexProtocol) -> Void) {
        let index = PositionalInvertedIndex()
        
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
                    index.addTerm(stemmed, withId: document.documentId, atPosition: position)
                }
                DispatchQueue.main.async {
                    self.initDelegate?.onEnvironmentIndexedDocument(withFileName: document.fileName)
                }
            }
            
            var typeNb = 1
            DispatchQueue.main.async {
                self.initDelegate?.onEnvironmentGramsIndexingStarted(gramsToIndex: types.count)
            }
            
            for type in types {
                index.kGramIndex.registerGramsFor(type: type)
                DispatchQueue.main.async {
                    self.initDelegate?.onEnvironmentIndexedGram(gramNumber: typeNb)
                }
                typeNb += 1
            }
            DispatchQueue.main.async {
                completion(index)
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
