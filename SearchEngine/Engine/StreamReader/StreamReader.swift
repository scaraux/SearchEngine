import Foundation

class StreamReader {
    
    let encoding: String.Encoding
    let chunkSize: Int
    var fileHandle: FileHandle?
    var data: Data?
    let delimData: Data
    var buffer: Data
    var atEof: Bool
    
    init?(path: String, delimiter: String = "\r\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {
        
        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    init?(url: URL, delimiter: String = "\r\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {
        
        guard let fileHandle = try? FileHandle(forReadingFrom: url),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    init?(data: Data, delimiter: String = "\r\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {
        
        guard let delimData = delimiter.data(using: encoding) else {
            return nil
        }
        
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.data = data
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }
    
    deinit {
        self.close()
    }
    
    private func readData() -> Data {
        if let fileHandle = self.fileHandle {
            return fileHandle.readData(ofLength: self.chunkSize)
        }
        
        if self.data != nil {
            let subDataCount = self.data!.count < self.chunkSize ? self.data!.count : self.chunkSize
            let subData = self.data!.subdata(in: 0..<subDataCount)
            self.data!.removeSubrange(0..<subDataCount)
            return subData
        }
        return Data()
    }

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil || data != nil, "Attempt to read from closed file")
        
        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            
            let tmpData: Data = readData()
            if tmpData.count > 0 {
                buffer.append(tmpData)
            }
            else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }
    
    /// Start reading from the beginning of file.
    func rewind() {
        fileHandle?.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
        data = nil
    }
}

extension StreamReader: Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}
