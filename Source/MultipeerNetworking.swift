// Copyright (c) David Bagwell - https://github.com/dbagwell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public struct Empty: Codable {
    
    public init() { }
    
}

extension Error {
    
    public var message: String {
        var message = ""
        
        if !(self is String) {
            message += "\(type(of: self)): "
        }
        
        message += "\(self)"
        
        return message
    }
    
}

open class PrettyJSONEncoder: JSONEncoder {
    
    public override init() {
        super.init()
        self.outputFormatting = .prettyPrinted
    }
    
}

extension String {
    public func prefixUTF8Bytes(_ numberOfBytes: Int) -> String {
        guard numberOfBytes > 0 else { return "" }
        
        if let substring = String(self.utf8.prefix(numberOfBytes)) {
            return substring
        }
        
        return self.prefixUTF8Bytes(numberOfBytes-1)
    }
    
    public func removingCharacters(in characterSet: CharacterSet) -> String {
        let remainingCharacters = self.unicodeScalars.filter { !characterSet.contains($0) }
        return String(String.UnicodeScalarView(remainingCharacters))
    }
    
    public func removingAdjacentOccurences(of soloString: String) -> String {
        var newString = self
        let stringToReplace = soloString+soloString
        
        while newString.contains(stringToReplace) {
            newString = newString.replacingOccurrences(of: stringToReplace, with: soloString)
        }
        
        return newString
    }
}
