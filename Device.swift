//
//  Device.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Device: NSObject {
	let peerID: MCPeerID
	var session: MCSession?
	var name: String
	var state = MCSessionState.notConnected
	var lastMessageReceived: Message?
    
    let message = "This is a string test!"

    var outputStream: OutputStream?
    
    var error: NSError? = nil
	
	init(peerID: MCPeerID) {
		self.name = peerID.displayName
		self.peerID = peerID
		super.init()
	}
	
	func connect() {
		if self.session != nil { return }
		
		self.session = MCSession(peer: MPCManager.instance.localPeerID, securityIdentity: nil, encryptionPreference: .required)
		self.session?.delegate = self
        
        do {
            outputStream = try self.session?.startStream(withName: "chat", toPeer: self.peerID)

            if let outputStream = outputStream {
                outputStream.delegate = self as? StreamDelegate
                outputStream.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
                outputStream.open()
            }

            let data = message.data(using: String.Encoding.utf8)!
            let bytesWritten = data.withUnsafeBytes {
                outputStream?.write($0, maxLength: data.count)
            }
            print("bytesWritten: \(String(describing: bytesWritten))")
        } catch {
            print("Error: \(error)")
        }
	}
	
	func disconnect() {
		self.session?.disconnect()
		self.session = nil
	}
	
	func invite(with browser: MCNearbyServiceBrowser) {
		self.connect()
		browser.invitePeer(self.peerID, to: self.session!, withContext: nil, timeout: 10)
	}
    
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            let input = aStream as! InputStream
            var buffer = [UInt8](repeating: 0, count: 1024)
            let numberBytes = input.read(&buffer, maxLength: 1024)
            let dataString = NSData(bytes: &buffer, length: numberBytes)
            let message = NSKeyedUnarchiver.unarchiveObject(with: dataString as Data) as! String
            print("Message recieved as stream \(message)")
        case Stream.Event.hasSpaceAvailable:
            break
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
        stream.delegate = self as? StreamDelegate
        stream.schedule(in: RunLoop.main, forMode: RunLoop.Mode.default)
        stream.open()
    }
	
	public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }

	public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }

}
