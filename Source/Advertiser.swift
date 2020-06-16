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

class Advertiser: MCNearbyServiceAdvertiser, MCNearbyServiceAdvertiserDelegate {
    
    // MARK: - Properties
    
    private let session: Session
    
    override var delegate: MCNearbyServiceAdvertiserDelegate? {
        get {
            return super.delegate
        } set {
            // Don't let others set this
        }
    }
    
    
    // MARK: - Init
    
    init(session: Session) {
        self.session = session
        super.init(peer: session.myPeerID, discoveryInfo: nil, serviceType: session.serviceType)
        super.delegate = self
    }
    
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard
            let context = context,
            let joinCode = String(data: context, encoding: .utf8)
            else {
                Logger.log("Host `\(self.myPeerID.displayName)` of service type `\(self.session.serviceType)` received invitation from peer `\(peerID.displayName)` without context.", for: .session)
                invitationHandler(false, nil)
                return
        }
        
        guard joinCode == self.session.joinCode else {
            Logger.log("Host `\(self.myPeerID.displayName)` of service type `\(self.session.serviceType)` received invitation from peer `\(peerID.displayName)` with incorrect join code `\(joinCode)`, expecting `\(self.session.joinCode)`.", for: .session)
            invitationHandler(false, nil)
            return
        }
        
        Logger.log("Host `\(self.myPeerID.displayName)` of service type `\(self.session.serviceType)` received invitation from peer `\(peerID.displayName)` with correct join code `\(joinCode)`, accepting invitation.", for: .session)
        invitationHandler(true, self.session)
    }
    
}
