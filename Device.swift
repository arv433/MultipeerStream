//
//  Device.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Device: NSObject, StreamDelegate {
    let peerID: MCPeerID
    var session: MCSession?
    var name: String
    var incomingStream: InputStream?
    var outgoingStream: OutputStream?
    var state = MCSessionState.notConnected {
        didSet {
            if state == .connected {
                do {
                    print("Starting Stream with \(self.peerID.displayName)")
                    outgoingStream = try self.session?.startStream(withName: "\(MPCManager.instance.localPeerID.displayName) - \(self.peerID.displayName)", toPeer: self.peerID)
                    print("Stream success with \(self.peerID.displayName)")
                    outgoingStream?.open()
                    
                    // write message after stream was opened
                    
                    if let outgoingStream = self.outgoingStream {
                        let data = "This is a test message".data(using: String.Encoding.utf8)!
                        let bytesWritten = data.withUnsafeBytes { outgoingStream.write($0, maxLength: data.count) }
                        print("Bytes written: \(String(describing: bytesWritten))")
                    }
                } catch {
                    print("Error streaming to \(self.peerID.displayName): \(error)")
                }
            }
        }
    }
    var lastMessageReceived: Message?
    
    init(peerID: MCPeerID) {
        self.name = peerID.displayName
        self.peerID = peerID
        super.init()
    }
    
    func connect() {
        if self.session != nil { return }
        
        self.session = MCSession(peer: MPCManager.instance.localPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session?.delegate = self
    }
    
    func disconnect() {
        self.session?.disconnect()
        self.session = nil
    }
    
    func invite(with browser: MCNearbyServiceBrowser) {
        self.connect()
        browser.invitePeer(self.peerID, to: self.session!, withContext: nil, timeout: 10)
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("Stream changed")
        switch eventCode {
        case .hasBytesAvailable:
            let data = Data(reading: aStream as! InputStream)
            if let message = String(data: data, encoding: .utf8) {
                print(message)
            } else {
                print("Can't decode message")
            }
        default:
            break
        }
    }
    
}

extension Device: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.state = state
        NotificationCenter.default.post(name: MPCManager.Notifications.deviceDidChangeState, object: self)
    }
    
    static let messageReceivedNotification = Notification.Name("DeviceDidReceiveMessage")
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = try? JSONDecoder().decode(Message.self, from: data) {
            self.lastMessageReceived = message
            NotificationCenter.default.post(name: Device.messageReceivedNotification, object: message, userInfo: ["from": self])
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        stream.delegate = self
        stream.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
        stream.open()
        incomingStream = stream
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
