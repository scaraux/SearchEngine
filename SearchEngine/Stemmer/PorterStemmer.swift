//
//  PorterStemmer.swift
//  PorterStemmer
//
//  Created by Vincent Coetzee on 2017/01/25.
//  Copyright © 2017 Vincent Coetzee
//
//  The Porter Stemming Algorithm was developed by Martin Porter.
//  You can find his algorithms and implementations at
//
//  https://tartarus.org/martin/PorterStemmer/
//
//  This Swift framework is distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/vincent-coetzee/PorterStemmer
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public class PorterStemmer
    {
    internal let _stemmer:OpaquePointer
    
    public init?()
        {
        if let stemmer = create_stemmer()
            {
            _stemmer = stemmer
            }
        else
            {
            return(nil)
            }
        }
    
    deinit
        {
        free_stemmer(_stemmer)
        }
    
    public func stem(_ string:String) -> String
        {
        guard !string.isEmpty else
            {
            return("")
            }
            
        var bytes = string.utf8CString
        var stemmedString:String = ""

        bytes.withUnsafeMutableBufferPointer
            {
            pointer in
            let address = pointer.baseAddress!
            let length = strlen(address)
            guard length > 0 else
                {
                return
                }
                
            let stopIndex = Int(stemm(_stemmer,address,Int32(length-1)))
            guard stopIndex >= 0 else
                {
                return
                }
            pointer[stopIndex+1] = 0
            stemmedString = String(cString: address)
            }
        return(stemmedString)
        }
    }
