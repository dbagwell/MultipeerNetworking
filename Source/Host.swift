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

public final class Host: Networker {
    
    // MARK: - Properties
    
    private lazy var advertiser: Advertiser = {
        let advertiser = Advertiser(session: self.session)
        return advertiser
    }()
    
    override var defaultRequestRecipients: [NetworkerID] {
        return self.session.connectedPeerIDs
    }
    
    
    // MARK: - Init
    
    public override init(name: String, serviceType: String, joinCode: String?, configuration: NetworkerConfiguration = .default) {
        let joinCode = joinCode ?? "\(Int.random(in: 1000...9999))"
        super.init(name: name, serviceType: serviceType, joinCode: joinCode, configuration: configuration)
    }
    
    
    // MARK: - Methods
    
    public func start() {
        Logger.log("Starting Host `\(self.name)` of service type `\(self.serviceType)`.", for: .session)
        self.advertiser.startAdvertisingPeer()
    }
    
    public func stop() {
        Logger.log("Stopping Host `\(self.name)` of service type `\(self.serviceType)`.", for: .session)
        self.session.disconnect()
        self.advertiser.stopAdvertisingPeer()
    }
    
    
    // MARK: - Deinit
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
    }
    
}
