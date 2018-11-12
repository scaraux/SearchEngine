//
//  BinaryFile.swift
//  SearchEngine
//
//  Created by Oscar Götting on 10/29/18.
//  Copyright © 2018 Oscar Götting. All rights reserved.
//
// swiftlint:disable implicit_getter

import Foundation

class BinaryFile {
    
    private(set) var offsets: [UInt64] = []
//    private(set) var headOffset: UInt64 = 0
    private(set) var handle: FileHandle?
    private(set) var url: URL
    private var currentOffset: UInt64 = 0
    private var buffer: Data
    
    var size: UInt64 {
        get {
            return self.fileSize(forURL: self.url)
        }
    }
    
    init(atPath url: URL, for mode: DiskConstants.FileDescriptorMode = .reading) throws {
        self.url = url
        self.buffer = Data()
        
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
                                        for mode: DiskConstants.FileDescriptorMode = .reading) throws -> BinaryFile {
        if !FileManager.default.fileExists(atPath: url.path) {
            var isDir: ObjCBool = true
            if !FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path, isDirectory: &isDir) {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        return try BinaryFile(atPath: url, for: mode)
    }
    
    public func write(data: Data) {
        self.handle!.write(data)
        self.offsets.append(self.currentOffset)
        self.currentOffset += UInt64(data.count)
    }
    
    public func placeHeadAt(offset: UInt64) {
        self.buffer = Data()
//        self.headOffset = offset
        self.handle!.seek(toFileOffset: offset)
    }
    
//    public func read(chunkSize: Int) -> Data {
//        var data: Data
//        if self.buffer.count < chunkSize {
//            let tmpBuffer: Data = self.handle!.readData(ofLength: 4096)
//            self.buffer.append(tmpBuffer)
//        }
//        if self.buffer.count < chunkSize {
//            data = self.buffer.subdata(in: 0..<self.buffer.count)
//            self.buffer.removeSubrange(0..<self.buffer.count)
//            self.headOffset += UInt64(self.buffer.count)
//        } else {
//            data = self.buffer.subdata(in: 0..<chunkSize)
//            self.buffer.removeSubrange(0..<chunkSize)
//            self.headOffset += UInt64(chunkSize)
//        }
//        return data
//    }

    public func read(chunkSize: Int) -> Data {
        return self.handle!.readData(ofLength: chunkSize)
    }
    
    public func readUntilEndOfFileAt(offset: UInt64) -> Data {
        self.buffer = Data()
//        self.headOffset = self.handle!.offsetInFile
        self.handle!.seek(toFileOffset: offset)
        return self.handle!.readDataToEndOfFile()
    }
    
    public func getOffset() -> UInt64 {
        return self.handle!.offsetInFile
    }
    
    public func readInteger<I: FixedWidthInteger>() -> I? {
        let data: Data = self.read(chunkSize: MemoryLayout<I>.size)
        if data.count == 0 {
            return nil
        }
        return data.withUnsafeBytes { $0.pointee } as I
    }
    
    public func readDouble() -> Double? {
        let data: Data = self.read(chunkSize: MemoryLayout<Double>.size)
        if data.count == 0 {
            return nil
        }
        return data.withUnsafeBytes { $0.pointee } as Double
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
