//
//  BinaryFile.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//
// swiftlint:disable nesting implicit_getter

import Foundation

class BinaryFile {
    
    private var handle: FileHandle?
    private var url: URL
    private var currentOffset: Int64 = 0
    private(set) var offsets: [Int64] = []
    
    struct BinaryFileOptions {
        enum FileDescriptorMode {
            case reading
            case writing
            case updating
        }
    }
    
    var size: UInt64 {
        get {
            return self.fileSize(forURL: self.url)
        }
    }
    
    init(atPath url: URL, for mode: BinaryFileOptions.FileDescriptorMode = .reading) throws {
        self.url = url
    
        switch mode {
        case .reading:
            self.handle = try FileHandle(forReadingFrom: url)
        case .writing:
            self.handle = try FileHandle(forWritingTo: url)
        case .updating:
            self.handle = try FileHandle(forUpdating: url)
        }
    }
    
    public static func createBinaryFile(atPath url: URL,
                                        for mode: BinaryFileOptions.FileDescriptorMode = .reading) -> BinaryFile? {
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                var isDir: ObjCBool = true
                if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) {
                    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                }
                if !FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil) {
                    return nil
                }
            } catch {
                return nil
            }
        }
        do {
            return try BinaryFile(atPath: url, for: mode)
        } catch let error as NSError {
            print(error.description)
            return nil
        }
    }
    
    public func write(data: Data) {
        self.handle!.write(data)
        self.offsets.append(self.currentOffset)
        self.currentOffset += Int64(data.count)
    }
    
    public func move(toOffset offset: UInt64) {
        self.handle!.seek(toFileOffset: offset)
    }
    
    public func read(chunkSize: Int) -> Data {
        return self.handle!.readData(ofLength: chunkSize)
    }
    
    public func dispose() {
        self.handle!.closeFile()
    }
    
    private func fileSize(forURL url: URL) -> UInt64 {
        var fileSize: UInt64 = 0
        try? fileSize = (url.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
            .allValues.first?.value as! UInt64)
        return fileSize
    }
}
