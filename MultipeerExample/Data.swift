//
//  Data.swift
//  MultipeerExample
//
//  Created by Arvin Zojaji on 2019-01-02.
//  Copyright © 2019 Stand Alone, Inc. All rights reserved.
//

import Foundation

extension Data {
    init(reading input: InputStream) {
        self.init()
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if (read == 0) {
                print("Failed to read, breaking")
                break
            }
            self.append(buffer, count: read)
        }
        
        buffer.deallocate()
    }
}
