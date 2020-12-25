//
//  Cleanup.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import ShellOut


extension BitbucketEvent {
    func cleanup(on request: Request) throws -> EventLoopFuture<Void> {
        request.logger.debug("Cleaning up the source code directory at \(sourceCodeDirectory)")
        
        try shellOut(to: "rm -rf \(sourceCodeDirectory)")
        
        return request.eventLoop.makeSucceededFuture(Void())
    }
}
