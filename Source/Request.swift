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

public protocol RequestHandler: class {
    func didReceive(_ request: Request)
}

public final class Request: Message {
    
    private enum CodingKey: Swift.CodingKey {
        case expectsResponse
    }
    
    
    // MARK: - Properties
    
    public let expectsResponse: Bool
    
    
    // MARK: - Init
    
    init<Body: Codable>(requesterID: String, exchangeTypeID: String, body: Body, expectsResponse: Bool) {
        self.expectsResponse = expectsResponse
        super.init(exchangeID: UUID(), requesterID: requesterID, exchangeTypeID: exchangeTypeID,messageType: .request, body: body)
    }
    
    
    // MARK: - Decodable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        self.expectsResponse = try container.decode(Bool.self, forKey: .expectsResponse)
        try super.init(from: decoder)
    }
    
    
    // MARK: - Encodable
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        try container.encode(self.expectsResponse, forKey: .expectsResponse)
        try super.encode(to: encoder)
    }
    
    
    // MARK: - Methods
    
    public func extractBody<Body: Codable>() throws -> Body {
        guard let body = self.body as? Body else {
            let errorMessage = "Unable to extract `body` from `request` of type `\(self.exchangeTypeID)` as `\(Body.self)`, `body` is of type `\(type(of: self.body))`.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        return body
    }
    
    func response<Body: Codable>(withBody body: Body) throws -> Response {
        guard self.expectsResponse else {
            let errorMessage = "Trying to create a response for a \(type(of: self)) of type `\(self.exchangeTypeID)` that is not expecting one.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        return Response(exchangeID: self.exchangeID, requesterID: self.requesterID, exchangeTypeID: self.exchangeTypeID, body: body, isError: false)
    }
    
    func errorResponse(withError error: String) throws -> Response {
        guard self.expectsResponse else {
            let errorMessage = "Trying to create a response for a \(type(of: self)) of type `\(self.exchangeTypeID)` that is not expecting one.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        return Response(exchangeID: self.exchangeID, requesterID: self.requesterID, exchangeTypeID: self.exchangeTypeID, body: error, isError: true)
    }
    
}
