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

public final class Client: Networker {
    
    // MARK: - Properties
    
    private var hostID: NetworkerID?
    
    private lazy var browser: Browser = {
        let delegate = Browser(session: self.session)
        return delegate
    }()
    
    override var defaultRequestRecipients: [NetworkerID] {
        return [self.hostID].compact()
    }
    
    private var pendingExchanges = [Exchange]()
    
    
    // MARK: - Init
    
    public override init(name: String, serviceType: String, joinCode: String, configuration: NetworkerConfiguration = .default) {
        super.init(name: name, serviceType: serviceType, joinCode: joinCode, configuration: configuration)
    }
    
    
    // MARK: - Methods
    
    override func handleNoRecipients(for exchange: Exchange) {
        self.pendingExchanges.append(exchange)
        Logger.log("Client `\(self.name)` of service type `\(self.serviceType)` starting to look for hosts.", for: .session)
        self.browser.startBrowsingForPeers()
    }
    
    
    // MARK: - SessionDelegate
    
    override func sessionDidConnect(to peer: NetworkerID) {
        guard self.hostID == nil else { return }
        
        self.browser.stopBrowsingForPeers()
        super.sessionDidConnect(to: peer)
        self.hostID = peer
        
        for exchange in self.pendingExchanges {
            self.beginExchange(exchange)
        }
        
        self.pendingExchanges.removeAll()
    }
    
    override func sessionDidDisconnect(from peer: NetworkerID) {
        super.sessionDidDisconnect(from: peer)
        self.hostID = nil
        self.browser.startBrowsingForPeers()
    }
    
    
    // MARK: - Deinit
    
    deinit {
        self.browser.stopBrowsingForPeers()
    }
    
}
