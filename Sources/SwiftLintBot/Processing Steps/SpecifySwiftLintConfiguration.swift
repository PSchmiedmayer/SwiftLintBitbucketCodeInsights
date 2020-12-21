//
//  SpecifySwiftLintConfiguration.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor


extension BitbucketEvent {
    func specifySwiftLintConfiguration(on request: Request) throws -> EventLoopFuture<Void> {
        request.eventLoop.makeSucceededFuture(Void())
    }
}
