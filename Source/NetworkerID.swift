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

import MultipeerConnectivity

public final class NetworkerID: MCPeerID, Decodable {
    
    enum CodingKey: Swift.CodingKey {
        case data
    }
    
    
    // MARK: - Init
    
    public override init(displayName: String) {
        super.init(displayName: displayName)
    }
    
    
    // MARK: - Decoable
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        
        let data = try container.decode(Data.self, forKey: .data)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        self.init(coder: unarchiver)!
    }
    
    
    // MARK: - NSCoding
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
}

extension MCPeerID: Encodable {
    
    public var networkerID: NetworkerID {
        let data = try! JSONEncoder().encode(self)
        return try! JSONDecoder().decode(NetworkerID.self, from: data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NetworkerID.CodingKey.self)
        
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        self.encode(with: archiver)
        
        let data = archiver.encodedData
        try container.encode(data, forKey: .data)
    }
    
}
