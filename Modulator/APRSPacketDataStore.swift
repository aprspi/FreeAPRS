//
//  APRSPacketDataStore.swift
//  FreeAPRS
//
//  Created by James on 11/15/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSPacketDataStore: Sequence, Collection {
    var backingArray = [APRSPacket]()
    private let accessQueue = DispatchQueue(label: "ThreadSafeArrayAccess", attributes: .concurrent)
    
    var startIndex : Int { return 0 }
    var endIndex : Int { return backingArray.count - 1 }
    var count : Int {
        var count = 0
        
        self.accessQueue.sync {
            count = self.backingArray.count
        }
        return count
    }
    
    func index(after i: Int) -> Int {
        guard i != endIndex else { fatalError("Cannot increment endIndex") }
        return i + 1
    }
    
    func append(packet: APRSPacket) {
        self.accessQueue.async(flags:.barrier) {
            self.backingArray.append(packet)
        }
    }
    
    subscript(index: Int) -> APRSPacket {
        get {
            var element: APRSPacket!
            self.accessQueue.sync {
                assert(index >= 0 && index < self.backingArray.count)
                element = backingArray[index]
            }
            
            return element
        }
        
        set (newValue) {
            self.accessQueue.async(flags:.barrier) {
                assert(index >= 0 && index < self.backingArray.count)
                self.backingArray[index] = newValue
            }
        }
    }
    
    func remove(at: Int) {
        self.accessQueue.async(flags:.barrier) {
            assert(at >= 0 && at < self.backingArray.count)
            self.backingArray.remove(at: at)
        }
    }
}
