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
import Rebar

public class Networker: SessionDelegate, ExchangeTimeoutDelegate {
    
    // MARK: - Properties
    
    let name: String
    let serviceType: String
    public let joinCode: String
    private let configuration: NetworkerConfiguration
    public weak var requestHandler: RequestHandler?
    
    private var peerIDKey: String {
        return [self.serviceType, self.name].joined(separator: ".")
    }
    
    public private(set) lazy var id: NetworkerID = {
        return NetworkerID(displayName: self.name)
    }()
    
    lazy var session: Session = {
        let session = Session(peer: self.id, serviceType: self.serviceType, networkerType: "\(type(of: self))", joinCode: self.joinCode)
        session.sessionDelegate = self
        return session
    }()
    
    var defaultRequestRecipients: [NetworkerID] {
        return []
    }
    
    private var pendingExchanges = [UUID: Exchange]()
    
    
    // MARK: - Init
    
    init(name: String, serviceType: String, joinCode: String, configuration: NetworkerConfiguration = .default) {
        self.name = name.prefixUTF8Bytes(63)
        self.serviceType = String(serviceType.lowercased().removingCharacters(in: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz1234567890-").inverted).removingAdjacentOccurences(of: "-").prefix(15))
        self.joinCode = joinCode
        self.configuration = configuration
        
        Logger.log("Initializing \(type(of: self)) with name `\(self.name)` for service type `\(self.serviceType)`.", for: .session)
    }
    
    
    // MARK: - Registering Exchange
    
    // The following three methods are overloads of the same method because we can't give generic parameters default values, cause we don't know what type they will be called with
    // With Request Type and Response Type
    public func register<RequestBody: Codable, RespnoseBody: Codable>(requestBodyType: RequestBody.Type, responseBodyType: RespnoseBody.Type, forExchangeTypeID exchangeTypeID: String) {
        Message.registerEncoderDecoder(for: requestBodyType, forExchangeTypeID: exchangeTypeID, messageType: .request)
        Message.registerEncoderDecoder(for: responseBodyType, forExchangeTypeID: exchangeTypeID, messageType: .response)
        Message.registerEncoderDecoder(for: String.self, forExchangeTypeID: exchangeTypeID, messageType: .errorResponse)
    }
    
    // With Request Type Only
    public func register<RequestBody: Codable>(requestBodyType: RequestBody.Type, forExchangeTypeID exchangeTypeID: String) {
        Message.registerEncoderDecoder(for: requestBodyType, forExchangeTypeID: exchangeTypeID, messageType: .request)
    }
    
    // With Response Type Only
    public func register<RespnoseBody: Codable>(responseBodyType: RespnoseBody.Type, forExchangeTypeID exchangeTypeID: String) {
        Message.registerEncoderDecoder(for: Empty.self, forExchangeTypeID: exchangeTypeID, messageType: .request)
        Message.registerEncoderDecoder(for: responseBodyType, forExchangeTypeID: exchangeTypeID, messageType: .response)
        Message.registerEncoderDecoder(for: String.self, forExchangeTypeID: exchangeTypeID, messageType: .errorResponse)
    }
    
    
    // MARK: - Sending Requests
    
    // The following four methods are overloads of the same method because we can't give generic parameters default values, cause we don't know what type they will be called with
    // With Request Body and Response Handler
    public func beginExchange<RequestBody: Codable, ResponseBody: Codable>(ofType type: String, withRequestBody requestBody: RequestBody, handlingResponseWith responseHandler: @escaping ResponseHandler<ResponseBody>) {
        let exchange = Exchange(typeID: type, requestBody: requestBody, requesterID: self.id.displayName, responseHandler: responseHandler, timeout: self.configuration.exchangeTimeoutInterval, timeoutDelegate: self)
        self.beginExchange(exchange)
    }
    
    // With Request Body Only
    public func beginExchange<RequestBody: Codable>(ofType type: String, withRequestBody requestBody: RequestBody) {
        let exchange = Exchange(typeID: type, requestBody: requestBody, requesterID: self.id.displayName)
        self.beginExchange(exchange)
    }
    
    // With Response Handler Only
    public func beginExchange<ResponseBody: Codable>(ofType type: String, handlingResponseWith responseHandler: @escaping ResponseHandler<ResponseBody>) {
        let exchange = Exchange(typeID: type, requesterID: self.id.displayName, responseHandler: responseHandler, timeout: self.configuration.exchangeTimeoutInterval, timeoutDelegate: self)
        self.beginExchange(exchange)
    }
    
    // With neither Request Body nor Response Handler
    public func beginExchange(ofType type: String) {
        let exchange = Exchange(typeID: type, requesterID: self.id.displayName)
        self.beginExchange(exchange)
    }
    
    func beginExchange(_ exchange: Exchange) {
        guard !self.defaultRequestRecipients.isEmpty else {
            self.handleNoRecipients(for: exchange)
            return
        }
        
        self.pendingExchanges[exchange.request.exchangeID] = exchange
        
        self.send(exchange.request, to: self.defaultRequestRecipients, retry: self.configuration.numberOfTimesToRetrySendingMessages, andHandleResponseWith: exchange.responseHandlerWrapper)
    }
    
    private func send(_ request: Request, to recipents: [NetworkerID], retry retriesLeft: Int, andHandleResponseWith responseHandlerWrapper: AnyResponseHandlerWrapper? = nil) {
        do {
            let data = try JSONEncoder().encode(request)
            
            if Logger.isEnabled {
                let peerNames = recipents.map({ $0.displayName })
                
                do {
                    let prettyData = try PrettyJSONEncoder().encode(request)
                    let jsonString = String(data: prettyData, encoding: .utf8) ?? "ERROR: Unable to log request object."
                    Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` sending request to peers [\(peerNames)]:\n\n\(jsonString)", for: .request)
                } catch {
                    Logger.log("ERROR: Unable to log request in pretty format. Got error encoding it:\n\(error.message)\nLogging in non-pretty format instead.", for: .error)
                    let jsonString = String(data: data, encoding: .utf8) ?? "ERROR: Unable to log request object."
                    Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` sending request to peers [\(peerNames)]:\n\n\(jsonString)", for: .request)
                }
            }
            
            self.send(data, forExchangeID: request.exchangeID, to: self.defaultRequestRecipients, retry: self.configuration.numberOfTimesToRetrySendingMessages)
        } catch {
            self.callResponseHandler(forExchangeID: request.exchangeID, withErrorMessage: error.message)
        }
    }
    
    
    // MARK: - Sending Responses
    
    public func respond<ResponseBody: Codable>(to request: Request, withBody body: ResponseBody) {
        do {
            let response = try request.response(withBody: body)
            self.sendResponse(response)
        } catch {
            Logger.log(error.message, for: .error)
        }
    }
    
    public func respond(to request: Request, withError error: String) {
        do {
            let response = try request.errorResponse(withError: error)
            self.sendResponse(response)
        } catch {
            Logger.log(error.message, for: .error)
        }
    }
    
    private func send(_ response: Response, retry retriesLeft: Int, andHandleResponseWith responseHandlerWrapper: AnyResponseHandlerWrapper? = nil) {
        do {
            let data = try JSONEncoder().encode(response)
            
            if Logger.isEnabled {
                do {
                    let prettyData = try PrettyJSONEncoder().encode(response)
                    let jsonString = String(data: prettyData, encoding: .utf8) ?? "ERROR: Unable to log response object."
                    Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` sending response to peer `\(response.requesterID)`:\n\n\(jsonString)", for: .response)
                } catch {
                    Logger.log("ERROR: Unable to log response in pretty format. Got error encoding it:\n\(error.message)\nLogging in non-pretty format instead.", for: .error)
                    let jsonString = String(data: data, encoding: .utf8) ?? "ERROR: Unable to log response object."
                    Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` sending response to peer `\(response.requesterID)`:\n\n\(jsonString)", for: .response)
                }
            }
            
            guard let requesterID = self.session.connectedPeerIDs.first(where: { $0.displayName == response.requesterID })?.networkerID else {
                Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` failed sending response to peer `\(response.requesterID)`. Not connected to peer.", for: .error)
                return
            }
            
            self.send(data, forExchangeID: response.exchangeID, to: [requesterID], retry: self.configuration.numberOfTimesToRetrySendingMessages)
        } catch {
            Logger.log(error.message, for: .error)
        }
    }
    
    private func sendResponse(_ response: Response) {
        self.send(response, retry: self.configuration.numberOfTimesToRetrySendingMessages)
    }
    
    
    // MARK: - Sending Data
    
    private func send(_ data: Data, forExchangeID exchangeID: UUID, to recipents: [NetworkerID], retry retriesLeft: Int) {
        do {
            try self.session.send(data, toPeers: recipents, with: .reliable)
        } catch {
            guard retriesLeft > 0 else {
                let errorMessage = "Unable to send request. Retried \(self.configuration.numberOfTimesToRetrySendingMessages) times. Failed for unknown reason.\n(exchangeID: \(exchangeID))"
                Logger.log(errorMessage, for: .error)
                self.callResponseHandler(forExchangeID: exchangeID, withErrorMessage: errorMessage)
                return
            }
            
            self.send(data, forExchangeID: exchangeID, to: recipents, retry: retriesLeft-1)
        }
    }
    
    
    // MARK: - Other Methods
    
    private func callResponseHandler(forExchangeID exchangeID: UUID, withErrorMessage errorMessage: String) {
        self.pendingExchanges[exchangeID]?.timeoutTimer?.invalidate()
        self.pendingExchanges[exchangeID]?.responseHandlerWrapper?.callResponseHandler(withError: errorMessage)
        self.pendingExchanges[exchangeID] = nil
    }
    
    func handleNoRecipients(for exchange: Exchange) {
        let errorMessage = "Failed to send message, no recipients.\n(exchangeID: \(exchange.request.exchangeID))"
        Logger.log(errorMessage, for: .error)
        self.callResponseHandler(forExchangeID: exchange.request.exchangeID, withErrorMessage: errorMessage)
    }
    
    
    // MARK: - ExchangeTimeoutDelegate
    
    func requestDidTimeout(_ request: Request) {
        let errorMessage = "Request of type `\(request.exchangeTypeID)` timed out after \(self.configuration.exchangeTimeoutInterval) seconds.\n(exchangeID: \(request.exchangeID))"
        Logger.log(errorMessage, for: .error)
        self.pendingExchanges[request.exchangeID]?.responseHandlerWrapper?.callResponseHandler(withError: errorMessage)
        self.pendingExchanges[request.exchangeID] = nil
    }
    
    
    // MARK: - SessionDelegate
    
    func sessionDidConnect(to peer: NetworkerID) {
        Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` did connect to peer `\(peer.displayName)`", for: .session)
    }
    
    func sessionDidDisconnect(from peer: NetworkerID) {
        Logger.log("\(type(of: self)) `\(self.name)` of service type `\(self.serviceType)` did disconnect from peer `\(peer.displayName)`", for: .session)
    }
    
    func sessionDidReceive(_ request: Request) {
        self.requestHandler?.didReceive(request)
    }
    
    func sessionDidReceive(_ response: Response) {
        self.pendingExchanges[response.exchangeID]?.timeoutTimer?.invalidate()
        self.pendingExchanges[response.exchangeID]?.responseHandlerWrapper?.callResponseHandler(with: response)
        self.pendingExchanges[response.exchangeID] = nil
    }
    
    
    // MARK: - Deinit
    
    deinit {
        self.session.sessionDelegate = nil
        self.session.disconnect()
    }
    
}
