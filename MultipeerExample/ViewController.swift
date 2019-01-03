//
//  ViewController.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var inputField: UITextField!
    
    var devices: [Device] = []
    var selectedDevice: Device?
    
    @objc func reload(){
        self.devices = Array(MPCManager.instance.devices).sorted(by: { $0.name < $1.name })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: MPCManager.Notifications.deviceDidChangeState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: MPCManager.Notifications.deviceDidChangeState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Device.messageReceivedNotification, object: nil)
        
        self.reload()
    }
    
    @IBAction func readStreamButtonTapped(_ sender: UIButton) {
        guard let device = selectedDevice, let inputStream = device.incomingStream else { return }
        
        print(device.peerID.displayName)

        let data = Data(reading: inputStream)
        if let message = String(data: data, encoding: .utf8) {
            print(message)
        } else {
            print("Can't decode message")
        }
    }
    
    @IBAction func writeToStreamButtonTapped(_ sender: UIButton) {
        guard let text = inputField.text else { return }
        
        for device in devices {
            if let outgoingStream = device.outgoingStream {
                print("outgoing stream has space available: \(outgoingStream.hasSpaceAvailable)")
                if outgoingStream.hasSpaceAvailable {
                    let data = text.data(using: .utf8)!
                    let bytesWritten = data.withUnsafeBytes { outgoingStream.write($0, maxLength: data.count) }
                    print("Bytes written: \(String(describing: bytesWritten))")
                } else {
                    print("No space to write to reciever")
                }
            }
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let device = self.devices[indexPath.row]
        cell.textLabel?.text = "\(device.name) - \(device.state.rawValue)"
        cell.detailTextLabel?.text = device.lastMessageReceived?.body
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = self.devices[indexPath.row]
        self.selectedDevice = device
        let alert = UIAlertController(title: "Send To \(device.name)", message: "Enter your message:", preferredStyle: .alert)
        alert.addTextField { field in }
        
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { _ in
            if let text = alert.textFields?.first?.text {
                try? device.send(text: text)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
