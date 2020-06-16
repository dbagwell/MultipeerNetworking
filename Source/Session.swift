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

protocol SessionDelegate: class {
    func sessionDidConnect(to peer: NetworkerID)
    func sessionDidDisconnect(from peer: NetworkerID)
    func sessionDidReceive(_ request: Request)
    func sessionDidReceive(_ response: Response)
}

final class Session: MCSession, MCSessionDelegate {
    
    // MARK: - Properties
    
    weak var sessionDelegate: SessionDelegate?
    
    override var delegate: MCSessionDelegate? {
        get {
            return super.delegate
        } set {
            // Don't let others set this
        }
    }
    
    let serviceType: String
    let networkerType: String
    let joinCode: String
    
    var connectedPeerIDs: [NetworkerID] {
        return self.connectedPeers.map({ $0.networkerID })
    }
    
    
    // MARK: - Init
    
    init(peer myPeerID: MCPeerID, serviceType: String, networkerType: String, joinCode: String) {
        self.serviceType = serviceType
        self.networkerType = networkerType
        self.joinCode = joinCode
        
        super.init(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.delegate = self
    }
    
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            self.sessionDelegate?.sessionDidConnect(to: peerID.networkerID)
            
        case .notConnected:
            self.sessionDelegate?.sessionDidDisconnect(from: peerID.networkerID)
            
        case .connecting:
            break
            
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let request = try? JSONDecoder().decode(Request.self, from: data) {
            if Logger.isEnabled {
                do {
                    let prettyData = try PrettyJSONEncoder().encode(request)
                    let jsonString = String(data: prettyData, encoding: .utf8) ?? "ERROR: Unable to log request object."
                    Logger.log("\(self.networkerType) `\(self.myPeerID.displayName)` of service type `\(self.serviceType)` did receive request from peer `\(peerID.displayName)`:\n\n\(jsonString)", for: .request)
                } catch {
                    Logger.log("ERROR: Unable to log request in pretty format. Got error encoding it:\n\(error.message)\nLogging in non-pretty format instead.", for: .error)
                    let jsonString = String(data: data, encoding: .utf8) ?? "ERROR: Unable to log request object."
                    Logger.log("\(self.networkerType) `\(self.myPeerID.displayName)` of service type `\(self.serviceType)` did receive request from peer `\(peerID.displayName)`:\n\n\(jsonString)", for: .request)
                }
            }
            
            self.sessionDelegate?.sessionDidReceive(request)
        } else if let response = try? JSONDecoder().decode(Response.self, from: data) {
            if Logger.isEnabled {
                do {
                    let prettyData = try PrettyJSONEncoder().encode(response)
                    let jsonString = String(data: prettyData, encoding: .utf8) ?? "ERROR: Unable to log response object."
                    Logger.log("\(self.networkerType) `\(self.myPeerID.displayName)` of service type `\(self.serviceType)` received response from peer `\(peerID.displayName)`:\n\n\(jsonString)", for: .response)
                } catch {
                    Logger.log("ERROR: Unable to log response in pretty format. Got error encoding it:\n\(error.message)\nLogging in non-pretty format instead.", for: .error)
                    let jsonString = String(data: data, encoding: .utf8) ?? "ERROR: Unable to log response object."
                    Logger.log("\(self.networkerType) `\(self.myPeerID.displayName)` of service type `\(self.serviceType)` received response from peer `\(peerID.displayName)`:\n\n\(jsonString)", for: .response)
                }
            }
            
            self.sessionDelegate?.sessionDidReceive(response)
        } else {
            Logger.log("\(self.networkerType) `\(self.myPeerID.displayName)` of service type `\(self.serviceType)` received unknown message.", for: .session)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
