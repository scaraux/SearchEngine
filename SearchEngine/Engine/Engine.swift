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
    private let tokenProcessor: AdvancedTokenProcessor
    private var index: IndexProtocol?
    
    weak var delegate: EngineDelegate?
    weak var initDelegate: CreateEnvironmentDelegate?
    weak var loadDelegate: LoadEnvironmentDelegate?
    
    /// Modes for searching documents
    ///
    /// - boolean: Boolean Retrieval
    /// - ranked: Ranked Retrieval, retrieve document that best matches query
    /// using a score
    public enum SearchMode {
        case boolean
        case ranked
    }
    
    init() {
        self.booleanQueryParser = BooleanQueryParser()
        self.stemmer = PorterStemmer(withLanguage: .English)!
        self.tokenProcessor = AdvancedTokenProcessor()
    }
    
    /// Executes a query from a given query string
    /// Depending on the mode, the query will be executed
    /// as Boolean Retrieval query mode, or Ranked Retrieval
    /// query mode.
    /// Boolean Retrieval mode allows to return all document matching
    /// a formatted boolean logic (using OR, AND, operators within the
    /// query). Ranked retrieval uses a scoring and weight system, to
    /// return documents that matches the query the best
    ///
    /// - Parameters:
    ///   - queryString: Is the string describing the query
    ///   - mode: Is the mode used to search results, Boolean or Ranked
    func execQuery(queryString: String, mode: SearchMode) {
        // Check if Index is defined, otherwise fail
        guard let index = self.index else {
            print("No environment selected !")
            return
        }
        // Declare a Queriable object
        let query: Queriable?
        // If Search Mode is Boolean Retrieval, we parse the query
        if mode == .boolean {
            query = booleanQueryParser.parseQuery(query: queryString)
        }
        // If Search Mode is Ranked Retrieval, we instantiate a Ranked
        // Query object
        else {
            query = RankedQuery(withIndex: index, bagOfWords: queryString)
        }
        // Place in Thread
        DispatchQueue.global(qos: .userInteractive).async {
            // Retrieve results for Queriable object
            if var results: [QueryResult] = query?.getResultsFrom(index: index) {
                // Attach document to results
                results = self.attachDocumentsToResults(results: results)
                // Notify async
                DispatchQueue.main.async {
                    // Notify that query resulted and return the query results
                    self.delegate?.onQueryResulted(results: results)
                }
            }
            else {
                DispatchQueue.main.async {
                    // If no results, notify and return nil results
                    self.delegate?.onQueryResulted(results: nil)
                }
            }
        }
    }
    
    /// Return all terms known by the index
    ///
    /// - Returns: A list of terms as strings
    func getVocabulary() -> [String] {
        guard let index = self.index else {
            print("No environment selected !")
            return []
        }
       return index.getVocabulary()
    }
    
    /// Stem a given term
    ///
    /// - Parameter word: Is the term to be stemmed
    /// - Returns: A stem of the term as a string
    func stemWord(word: String) -> String {
        return self.stemmer.stem(word)
    }
    
    /// Loads an environment from a selected directory
    /// Directories where we search need to be indexed and written on disk
    /// using newEnvironment(atPath: URL)
    /// By loading an environment, the engine will search for a .index directory
    /// withing the path you provide
    /// Failure to locate this subdirectory, or read its binary files will results
    /// to a loading failure
    ///
    /// - Parameter url: Is the path of the directory where environment is located
    func loadEnvironment(withPath url: URL) {
        // If a current Index is loaded, release its resources
        if self.index != nil {
            self.index!
                .dispose()
        }
        // Place in thread
        DispatchQueue.global(qos: .userInteractive).async {
            // Load a new directory corpus to given path
            DirectoryCorpus.loadDirectoryCorpus(absolutePath: url)
            // Read documents
            DirectoryCorpus.shared.readDocuments()
            // Try to instantiate a Disk Environment Utility
            do {
                let utility = try ReadingDiskEnvUtility(atPath: url,
                                                   fileMode: .reading,
                                                   postingsEncoding: UInt32.self,
                                                   offsetsEncoding: UInt64.self)
                
                utility.loadDelegate = self.loadDelegate
                // Create a Gram Index
                let gramIndex: GramIndex = GramIndex(withMap: utility.getGramMap())
                // Create a Disk Positional Index, pass the utility
                self.index = DiskPositionalIndex(atPath: url, utility: utility, gramIndex: gramIndex)
                // Notify that environment has been loaded
                DispatchQueue.main.async {
                    self.loadDelegate?.onLoadingPhaseChanged(phase: .terminated, withTotalCount: 0)
                    self.delegate?.onEnvironmentLoaded()
                }
            } catch let error as NSError {
                // Notify a loading error
                DispatchQueue.main.async {
                    self.loadDelegate?.onLoadingPhaseChanged(phase: .terminated, withTotalCount: 0)
                    self.delegate?.onEnvironmentLoadingFailed(withError: error.localizedFailureReason!)
                }
            }
        }
    }
    
    /// Create a new environment for a corpus at selected directory
    /// An index will be generated and written to disk files
    ///
    /// - Parameter url: Is the url of the given directory
    func newEnvironment(withPath url: URL) {
        // Place in thread
        DispatchQueue.global(qos: .userInteractive).async {
            // Load corpus
            DirectoryCorpus.loadDirectoryCorpus(absolutePath: url)
            // Retrieve all documents in corpus asynchronously
            self.retrieveDocuments { (documents: [DocumentProtocol]) in
                // Notify that indexing started
                DispatchQueue.main.async {
                    self.initDelegate?.onInitializationPhaseChanged(phase: .phaseIndexingDocuments,
                                                                    withTotalCount: documents.count)
                }
                // Generate Positional Inverted Index in memory, asynchronously
                self.generateIndex(documents: documents, { index in
                    DispatchQueue.main.async {
                        self.initDelegate?.onInitializationPhaseChanged(phase: .phaseWritingIndex,
                                                                        withTotalCount: 0)
                    }
                    // Write index on disk
                    self.writeEnvironmentToDisk(atUrl: url, withIndex: index, withDocuments: documents)
                    // Notify that corpus has been initialized
                    DispatchQueue.main.async {
                        self.initDelegate?.onInitializationPhaseChanged(phase: .terminated,
                                                                        withTotalCount: 0)
                    }
                })
            }
        }
    }
    
    /// Write the environment permanently to the disk
    /// using binary files
    /// A Disk Environment Utility is created in writing mode
    /// and will write the Index and Weights to binary files on disk
    ///
    /// - Parameters:
    ///   - url: Is the path where files will be written
    ///   - index: Is the Index to be written
    ///   - documents: Are the documents whose weights will be written
    private func writeEnvironmentToDisk(atUrl url: URL,
                                        withIndex index: IndexProtocol,
                                        withDocuments documents: [DocumentProtocol]) {
        // Try to instantiate a Disk Environment Utility
        do {
            let utility = try WritingDiskEnvUtility(atPath: url,
                                               fileMode: .writing,
                                               postingsEncoding: UInt32.self,
                                               offsetsEncoding: UInt64.self)
            // Write the entire index to disk
            utility.writeIndex(index: index)
            // Write the entire gram-index to disk
            utility.writeKGramIndex(index: index.getKGramIndex())
            // Write weights for all documents
            utility.writeWeights(documents: documents)
            // Release the resources
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
        let docs: [DocumentProtocol] = DirectoryCorpus.shared.getDocuments()
        completion(docs)
    }
    
    /// Asynchronously generates an Index (PositionalInvertedIndex) from given documents.
    /// Each document is processed independently to retrieve all tokens
    ///
    /// - Parameters:
    ///   - documents: A list of documents part of the indexing process
    ///   - completion: A completion handler that returns the generated index
    private func generateIndex(documents: [DocumentProtocol], _ completion: @escaping (_: IndexProtocol) -> Void) {
        // Transform documents to a variable
        var documents = documents
        // Creates a PositionalInvertedIndex
        let index = PositionalInvertedIndex()
        // Create a hashset that will hold terms as unique values
        var types = Set<VocabularyType>()
        // Iterate over all documents
        for i in 0..<documents.count {
            // Retrieve current document
            var document = documents[i]
            // Synchronously notify that document has been indexed
            DispatchQueue.main.async {
                self.initDelegate?.onIndexingDocument(withFileName: document.fileName,
                                                      documentNb: i + 1,
                                                      totalDocuments: documents.count)
            }
            // Process document by adding its terms and types
            processDocument(index: index, document: &document, types: &types)
 
        } // End of iteration over all documents
        // Synchronously notify that K-Gram indexing started
        DispatchQueue.main.async {
            self.initDelegate?.onInitializationPhaseChanged(phase: .phaseIndexingGrams, withTotalCount: types.count)
        }
        // Initialize a type counter to 1
        var typeCounter = 1
        // Iterate over all types
        for vocabularyType in types {
            // Synchronously notify that type has been indexed
            DispatchQueue.main.async {
                self.initDelegate?.onIndexingGrams(forType: vocabularyType.raw,
                                                   typeNb: typeCounter,
                                                   totalTypes: types.count)
            }
            // Register K-Grams for current type
            index.kGramIndex.registerGramsFor(vocabularyType: vocabularyType)
            // Increment type counter
            typeCounter += 1
        }
        completion(index)
    }
    
    /// Each document is read, term by term to generate token stems.
    /// Each stem is associated to documents (postings) and each position
    /// of the term within its posting is specified
    ///
    /// - Parameters:
    ///   - index: The index where stems and postings are addes
    ///   - document: The current document to treat
    ///   - types: A list of unique types that appear in documents
    private func processDocument(index: PositionalInvertedIndex,
                                 document: inout DocumentProtocol,
                                 types: inout Set<VocabularyType>) {
        // Open a Stream Reader on document, fail if can't open
        guard let stream = document.getContent() else {
            fatalError("Error: Cannot create stream for file \(document.documentId)")
        }
        // Create a token stream, capable of retrieving all terms one at a time
        let tokenStream: TokenStreamProtocol = EnglishTokenStream(stream)
        // Initialize document weight
        var documentWeigth: Double = 0.0
        // Initialize a dictionary holding frequencies, mapping
        // a term with the number of times it appears within the current document
        var frequencies: [String: Int] = [:]
        // Retrieve tokens from the stream
        let tokens = tokenStream.getTokens()
        // Iterate over all tokens, as positions
        for position in 0..<tokens.count {
            // Retrieve current token
            let token = tokens[position]
            // Sanitize the token, by eleminiating unwanted characters
            let sanitized = tokenProcessor.processToken(token: token)
            // Stem the term, making it shorter and more generic
            let stem = self.stemWord(word: sanitized)
            // Insert the sanitized term to the hashset
            types.insert(VocabularyType(type: sanitized, stem: stem))
            // Add the term to the index, at position
            index.addTerm(stem, withId: document.documentId, atPosition: position)
            // If its the first time the term appears in document, set to 1
            if frequencies[stem] == nil {
                frequencies[stem] = 1
            }
            // Else increase the frequency
            else {
                frequencies[stem]! +=  1
            } // End of iteration over all tokens in document
        }
        // Iterate over all frequencies and calculate document weight
        for freq in frequencies {
            documentWeigth += pow(1 + log(Double(freq.value)), 2.0)
        }
        // Set the weight in document
        document.weight = sqrt(documentWeigth)
    }
    
    private func attachDocumentsToResults(results: [QueryResult]) -> [QueryResult] {
        for queryResult in results {
            queryResult.document = DirectoryCorpus.shared.getFileDocumentWith(id: queryResult.documentId)
        }
        return results
    }
}
