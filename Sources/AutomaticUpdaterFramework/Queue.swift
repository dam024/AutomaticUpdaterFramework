//
//  Queue.swift
//  Coproman Updater
//
//  Created by Jaccoud Damien on 26.03.24.
//

import Foundation

struct Queue<T : Any> {
    
    ///The items
    private var items: [T] = []
    
    var count: Int {
        self.items.count
    }
    
    var isEmpty: Bool {
        return self.items.count == 0
    }
    
    ///Return the first element in the queue
    func peek() -> T? {
        guard let topElement = items.first else { return nil }
        return topElement
    }
    
    ///Delete and return the first element in the queue
    @discardableResult
    mutating func pop() -> T? {
        if items.count > 0 {
            return items.removeFirst()
        }
        return nil
    }
  
    ///Push an element in the queue
    mutating func push(_ element: T) {
        items.append(element)
    }
    
    mutating func push(_ elements: [T]) {
        for element in elements {
            self.push(element)
        }
    }
    
    ///Empty the queue
    mutating func emptyStack() {
        self.items = []
    }
}
