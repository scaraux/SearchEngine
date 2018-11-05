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
    private var booleanQueryParser: BooleanQueryParser
    private let stemmer: PorterStemmer
    private var index: IndexProtocol?

    weak var delegate: EngineDelegate?
    weak var initDelegate: EngineInitDelegate?
    
    enum SearchMode {
        case boolean
        case ranked
    }
    
    init() {
        self.booleanQueryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
    }
    
    func execQuery(queryString: String, mode: SearchMode) {
        guard let index = self.index else {
            print("No environment selected !")
            return
        }
        let query: Queriable?
        
        if mode == .boolean {
            query = booleanQueryParser.parseQuery(query: queryString)
        }
        else {
            query = RankedQuery(withIndex: index, bagOfWords: queryString)
        }
        
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
    
        if self.index != nil {
            self.index!
                .dispose()
        }
        
        DirectoryCorpus.loadDirectoryCorpus(absolutePath: url)
        DirectoryCorpus.shared.readDocuments()
        
        do {
            let utility = try DiskEnvUtility(atPath: url,
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
        DirectoryCorpus.loadDirectoryCorpus(absolutePath: url)
        // Retrieve all documents in corpus asynchronously
        self.retrieveDocuments { (documents: [DocumentProtocol]) in
            // Notify that indexing started
            self.initDelegate?.onEnvironmentDocumentIndexingStarted(documentsToIndex: documents.count)
            // Generate Positional Inverted Index in memory, asynchronously
            self.generateIndex(documents: documents, { index in
                // Notify that corpus has been initialized
                self.initDelegate?.onEnvironmentInitialized(timeElapsed: self.calculateElapsedTime(from: start))
                // Write index on disk
                self.writeEnvironmentToDisk(atUrl: url, withIndex: index, withDocuments: documents)
                // Reload environment
                self.loadEnvironment(withPath: url)
            })
        }
    }
    
    private func writeEnvironmentToDisk(atUrl url: URL,
                                        withIndex index: IndexProtocol,
                                        withDocuments documents: [DocumentProtocol]) {
        do {
            let utility = try DiskEnvUtility(atPath: url,
                                               fileMode: .writing,
                                               postingsEncoding: UInt32.self,
                                               offsetsEncoding: UInt64.self)
            utility.writeIndex(index: index)
            utility.writeWeights(documents: documents)
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
    
    private func retrieveDocuments(completion: @escaping ([DocumentProtocol]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let docs: [DocumentProtocol] = DirectoryCorpus.shared.getDocuments()
            DispatchQueue.main.async {
                completion(docs)
            }
        }
    }
    
    private func generateIndex(documents: [DocumentProtocol], _ completion: @escaping (_: IndexProtocol) -> Void) {
        var documents = documents
        let index = PositionalInvertedIndex()

        DispatchQueue.global(qos: .userInteractive).async {
            
            let tokenProcessor = AdvancedTokenProcessor()
            var types = Set<String>()

            for i in 0..<documents.count {
                var document = documents[i]
                guard let stream = document.getContent() else {
                    fatalError("Error: Cannot create stream for file \(document.documentId)")
                }
                
                var documentWeigth: Double = 0.0
                var frequencies: [String: Int] = [:]
                let tokenStream: TokenStreamProtocol = EnglishTokenStream(stream)
                let tokens = tokenStream.getTokens()
                
                for position in 0..<tokens.count {
                    let token = tokens[position]
                    let sanitized = tokenProcessor.processToken(token: token)
                    types.insert(sanitized)
                    let stemmed = self.stemWord(word: sanitized)
                    index.addTerm(stemmed, withId: document.documentId, atPosition: position)
                    
                    let frequency = frequencies[stemmed]
                    if frequency == nil {
                        frequencies[stemmed] = 1
                    } else {
                        frequencies[stemmed] = frequency! + 1
                    }
                }
                
                for freq in frequencies {
                    documentWeigth += 1 + log(Double(freq.value))
                }
                
                document.weight = documentWeigth
                
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
            queryResult.document = DirectoryCorpus.shared.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
