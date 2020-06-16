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

import Rebar

public typealias ResponseHandler<BodyType: Codable> = (Result<BodyType, String>) -> Void

protocol AnyResponseHandlerWrapper {
    func callResponseHandler(with response: Response)
    func callResponseHandler(withError error: String)
}

struct ResponseHandlerWrapper<ResponseBody: Codable>: AnyResponseHandlerWrapper {
    
    // MARK: - Properties
    
    let responseHandler: ResponseHandler<ResponseBody>
    
    
    // MARK: - Methods
    
    func callResponseHandler(with response: Response) {
        if response.isError {
            guard let errorMessage = response.body as? String else {
                let errorMessage = "Unexpected error response for request of type `\(response.exchangeTypeID)`, expected `\(String.self)` but got `\(type(of: response.body))`.\n(exchangeID: \(response.exchangeID))"
                Logger.log(errorMessage, for: .error)
                self.responseHandler(.failure(errorMessage))
                return
            }
            
            self.responseHandler(.failure(errorMessage))
            
        } else {
            guard let body = response.body as? ResponseBody else {
                let errorMessage = "Unexpected response for request of type `\(response.exchangeTypeID)`, expected `\(ResponseBody.self)` but got `\(type(of: response.body))`.\n(exchangeID: \(response.exchangeID))"
                Logger.log(errorMessage, for: .error)
                self.responseHandler(.failure(errorMessage))
                return
            }
            
            self.responseHandler(.success(body))
        }
    }
    
    func callResponseHandler(withError error: String) {
        self.responseHandler(.failure(error))
    }
    
}
