//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor


extension EventLoopFuture {
    func mapThrowing<NewValue>(_ callback: @escaping (Value) throws -> NewValue) -> EventLoopFuture<NewValue> {
        flatMap { value in
            do {
                return self.eventLoop.makeSucceededFuture(try callback(value))
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }
    }

    func flatMapThrowing<NewValue>(_ callback: @escaping (Value) throws -> EventLoopFuture<NewValue>) -> EventLoopFuture<NewValue> {
        mapThrowing(callback).flatMap { $0 }
    }
}
