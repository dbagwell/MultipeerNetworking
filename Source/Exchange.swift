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

protocol ExchangeTimeoutDelegate: class {
    func requestDidTimeout(_ request: Request)
}

struct Exchange {
    
    // MARK: - Properties
    
    let request: Request
    let responseHandlerWrapper: AnyResponseHandlerWrapper?
    private(set) var timeoutTimer: Timer? = nil
    
    // MARK: - Init
    
    // The following four inits are overloads of the same init because we can't give generic parameters default values, cause we don't know what type they will be called with
    // With Request Body And Response Handler
    init<RequestBody: Codable, ResponseBody: Codable>(typeID: String, requestBody: RequestBody, requesterID: String, responseHandler: @escaping ResponseHandler<ResponseBody>, timeout: TimeInterval, timeoutDelegate: ExchangeTimeoutDelegate) {
        self.request = Request(requesterID: requesterID, exchangeTypeID: typeID, body: requestBody, expectsResponse: true)
        self.responseHandlerWrapper = ResponseHandlerWrapper(responseHandler: responseHandler)
        self.timeoutTimer = Timer(timeInterval: timeout, repeats: false, block: { [weak timeoutDelegate, request = self.request] timer in
            timer.invalidate()
            timeoutDelegate?.requestDidTimeout(request)
        })
        
        RunLoop.current.add(self.timeoutTimer!, forMode: .common)
    }
    
    // With Request Body Only
    init<RequestBody: Codable>(typeID: String, requestBody: RequestBody, requesterID: String) {
        self.request = Request(requesterID: requesterID, exchangeTypeID: typeID, body: requestBody, expectsResponse: false)
        self.responseHandlerWrapper = nil
    }
    
    // With Response Handler Only
    init<ResponseBody: Codable>(typeID: String, requesterID: String, responseHandler: @escaping ResponseHandler<ResponseBody>, timeout: TimeInterval, timeoutDelegate: ExchangeTimeoutDelegate) {
        self.request = Request(requesterID: requesterID, exchangeTypeID: typeID, body: Empty(), expectsResponse: true)
        self.responseHandlerWrapper = ResponseHandlerWrapper(responseHandler: responseHandler)
        self.timeoutTimer = Timer(timeInterval: timeout, repeats: false, block: { [weak timeoutDelegate, request = self.request] timer in
            timer.invalidate()
            timeoutDelegate?.requestDidTimeout(request)
        })
        
        RunLoop.current.add(self.timeoutTimer!, forMode: .common)
    }
    
    // With neither Request Body nor Response Handler
    init(typeID: String, requesterID: String) {
        self.request = Request(requesterID: requesterID, exchangeTypeID: typeID, body: Empty(), expectsResponse: true)
        self.responseHandlerWrapper = nil
    }
    
}
