//
//  Engine.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

<<<<<<< HEAD
/// The search engine core object
public class Engine {
    /// The index that contains associations between terms and postings
    private var index: PositionalInvertedIndex
    /// Module that writes the index to the file system
    private var indexWriter: DiskIndexWriter
    /// Parses queries to build a boolean, executable representation of it
=======
class Engine {
>>>>>>> 5f9844c84c01dea66e3003b71b759420e3272b96
    private var queryParser: BooleanQueryParser
    /// Stems terms
    private let stemmer: PorterStemmer
    /// Contains all documents relative to the index
    private var corpus: DocumentCorpusProtocol?
<<<<<<< HEAD
=======
    private var index: IndexProtocol?
>>>>>>> 5f9844c84c01dea66e3003b71b759420e3272b96

    weak var delegate: EngineDelegate?
    
    weak var initDelegate: EngineInitDelegate?
    
    /// Constructor
    init() {
        self.queryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
    }
    
    /// Executes a query
    ///
    /// - Parameter queryString: The query as a string
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
    
    /// Returns the complete vocabulary for the indexed directory
    ///
    /// - Returns: the vocabulary as a string array
    func getVocabulary() -> [String] {
        guard let index = self.index else {
            print("No environment selected !")
            return []
        }
       return index.getVocabulary()
    }
    
    /// Returns the stem for a given term
    ///
    /// - Parameter word: The word to be stemmed
    /// - Returns: The word's stem
    func stemWord(word: String) -> String {
        return self.stemmer.stem(word)
    }
    
<<<<<<< HEAD
    /// Initializes the engine with a corpus at a given path
    ///
    /// - Parameter path: Is the corpus path
    func initCorpus(withPath path: URL) {
=======
    func loadEnvironment(withPath url: URL) {
    
        if self.index != nil {
            self.index!
                .dispose()
        }
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
>>>>>>> 5f9844c84c01dea66e3003b71b759420e3272b96
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
                // Reload environment
                self.loadEnvironment(withPath: url)
            })
        }
    }
    
<<<<<<< HEAD
    
    /// Calculates elapsed time from a timestamp
    ///
    /// - Parameter startTime: is the timestamp reference
    /// - Returns: the difference as a double
    private func calculateElapsedTime(from startTime: DispatchTime) -> Double {
=======
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
>>>>>>> 5f9844c84c01dea66e3003b71b759420e3272b96
        let end = DispatchTime.now()
        let nanoTime = end.uptimeNanoseconds - startTime.uptimeNanoseconds
        return Double(nanoTime) / 1_000_000_000
    }
    
    /// Retrieves all documents asynchronously
    ///
    /// - Parameters:
    ///   - corpus: The corpus object containing data about documents
    ///   - completion: The completion handle that notifies when documents are ready to be indexed
    private func retrieveDocuments(corpus: DocumentCorpusProtocol,
                                   completion: @escaping ([DocumentProtocol]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let docs: [DocumentProtocol] = corpus.getDocuments()
            DispatchQueue.main.async {
                completion(docs)
            }
        }
    }
    
<<<<<<< HEAD
    /// Indexes all documents, by registering them in the map
    /// One document is processed at a time. Its content is read using
    /// a StreamReader, that produces a stream of tokens.
    /// Every token is processed, sanitized, stemmed, and added to the map.
    /// When all documents have been indexed, all unic terms are registered in the
    /// gram index.
    ///
    /// - Parameters:
    ///   - documents: All the documents to be indexed
    ///   - completion: The completion handler that notifies when documents are indexed
    private func indexDocuments(documents: [DocumentProtocol], completion: @escaping () -> Void) {
=======
    private func generateIndex(documents: [DocumentProtocol], _ completion: @escaping (_: IndexProtocol) -> Void) {
        let index = PositionalInvertedIndex()
        
>>>>>>> 5f9844c84c01dea66e3003b71b759420e3272b96
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
    
    /// Attaches the document back to each result
    ///
    /// - Parameter results: The results generated by a query
    /// - Returns: The sames results containing their respective document
    private func attachDocumentsToResults(results: [QueryResult]) -> [QueryResult] {
        for queryResult in results {
            queryResult.document = self.corpus?.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
