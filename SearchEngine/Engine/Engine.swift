//
//  Engine.swift
//  SearchEngine
//
//  Created by Oscar Götting on 9/20/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//

import Foundation
import PorterStemmer2

/// The search engine core object
public class Engine {
    /// The index that contains associations between terms and postings
    private var index: PositionalInvertedIndex
    /// Module that writes the index to the file system
    private var indexWriter: DiskIndexWriter
    /// Parses queries to build a boolean, executable representation of it
    private var queryParser: BooleanQueryParser
    /// Stems terms
    private let stemmer: PorterStemmer
    /// Contains all documents relative to the index
    private var corpus: DocumentCorpusProtocol?

    weak var delegate: EngineDelegate?
    
    weak var initDelegate: EngineInitDelegate?
    
    /// Constructor
    init() {
        self.index = PositionalInvertedIndex()
        self.indexWriter = DiskIndexWriter()
        self.queryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
    }
    
    /// Executes a query
    ///
    /// - Parameter queryString: The query as a string
    func execQuery(queryString: String) {
        let query: Queriable? = queryParser.parseQuery(query: queryString)

        if var results: [QueryResult] = query?.getResultsFrom(index: self.index) {
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
        return self.index.getVocabulary()
    }
    
    /// Returns the stem for a given term
    ///
    /// - Parameter word: The word to be stemmed
    /// - Returns: The word's stem
    func stemWord(word: String) -> String {
        return self.stemmer.stem(word)
    }
    
    /// Initializes the engine with a corpus at a given path
    ///
    /// - Parameter path: Is the corpus path
    func initCorpus(withPath path: URL) {
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
    
    
    /// Calculates elapsed time from a timestamp
    ///
    /// - Parameter startTime: is the timestamp reference
    /// - Returns: the difference as a double
    private func calculateElapsedTime(from startTime: DispatchTime) -> Double {
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
