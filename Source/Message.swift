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

enum MessageType: String, Codable {
    case request
    case response
    case errorResponse
}

public class Message: Codable {
    
    private typealias MessageBodyDecoder = (KeyedDecodingContainer<CodingKey>) throws -> Any
    private typealias MessageBodyEncoder = (Codable, inout KeyedEncodingContainer<CodingKey>) throws -> Void
    
    private static var messageBodyDecoders = [String: MessageBodyDecoder]()
    private static var messageBodyEncoders = [String: MessageBodyEncoder]()
    
    private static func encoderDecoderKey(exchangeTypeID: String, messageType: MessageType) -> String {
        return [exchangeTypeID, messageType.rawValue].joined(separator: ".")
    }
    
    static func registerEncoderDecoder<Body: Codable>(for bodyType: Body.Type, forExchangeTypeID exchangeTypeID: String, messageType: MessageType) {
        let key = self.encoderDecoderKey(exchangeTypeID: exchangeTypeID, messageType: messageType)
        
        self.messageBodyEncoders[key] = { anyBody, container in
            guard let body = anyBody as? Body else {
                let error = EncodingError.invalidValue(
                    anyBody,
                    EncodingError.Context(
                        codingPath: [CodingKey.body],
                        debugDescription: "Failed to encode `body` of \(messageType.rawValue) of type `\(exchangeTypeID)`, expected `\(Body.self)` but got `\(type(of: anyBody))`.)"
                ))
                Logger.log(error.message, for: .error)
                throw error
            }
            
            try container.encode(body, forKey: .body)
        }
        
        self.messageBodyDecoders[key] = { container in
            try container.decode(Body.self, forKey: .body)
        }
    }
    
    private enum CodingKey: Swift.CodingKey {
        case exchangeID
        case requesterID
        case exchangeTypeID
        case messageType
        case body
    }
    
    
    // MARK: - Properties
    
    let exchangeID: UUID
    public let requesterID: String
    public let exchangeTypeID: String
    let messageType: MessageType
    let body: Codable
    
    private var encodeDecoderKey: String {
        return Message.encoderDecoderKey(exchangeTypeID: self.exchangeTypeID, messageType: self.messageType)
    }
    
    
    // MARK: - Init
    
    init<Body: Codable>(exchangeID: UUID, requesterID: String, exchangeTypeID: String, messageType: MessageType, body: Body) {
        self.exchangeID = exchangeID
        self.requesterID = requesterID
        self.exchangeTypeID = exchangeTypeID
        self.messageType = messageType
        self.body = body
    }
    
    
    // MARK: - Decodable
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        self.exchangeID = try container.decode(UUID.self, forKey: .exchangeID)
        self.requesterID = try container.decode(String.self, forKey: .requesterID)
        self.exchangeTypeID = try container.decode(String.self, forKey: .exchangeTypeID)
        self.messageType = try container.decode(MessageType.self, forKey: .messageType)
        
        let decoderKey = Message.encoderDecoderKey(exchangeTypeID: self.exchangeTypeID, messageType: self.messageType)
        guard let messageBodyDecoder = Message.messageBodyDecoders[decoderKey] else {
            let errorMessage = "Failed to decode `body` of \(self.messageType.rawValue) of type `\(self.exchangeTypeID)`, missing decoder.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        guard let body = try messageBodyDecoder(container) as? Codable else {
            let errorMessage = "Failed to decode `body` of \(self.messageType.rawValue) of type `\(self.exchangeTypeID)`, message body was not `Codable`.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        self.body = body
    }
    
    
    // MARK: - Encodable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        try container.encode(self.exchangeID, forKey: .exchangeID)
        try container.encode(self.requesterID, forKey: .requesterID)
        try container.encode(self.exchangeTypeID, forKey: .exchangeTypeID)
        try container.encode(self.messageType, forKey: .messageType)
        
        guard let messageBodyEncoder = Message.messageBodyEncoders[self.encodeDecoderKey] else {
            let errorMessage = "Failed to encode `body` of \(self.messageType.rawValue) of type `\(self.exchangeTypeID)`, missing encoder.\n(exchangeID: \(self.exchangeID))"
            Logger.log(errorMessage, for: .error)
            throw errorMessage
        }
        
        try messageBodyEncoder(body, &container)
    }
    
}
