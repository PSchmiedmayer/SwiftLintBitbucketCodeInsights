//
//  DownloadSourceCode.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import ShellOut

extension BitbucketEvent {
    private var archiveRequetsURL: URI {
        "\(context.baseURL)/api/latest/projects/\(project.key)/repos/\(repository.key)/archive?at=\(pullRequest.commitHash)&filename=\(pullRequest.commitHash).zip&format=zip"
    }
    
    func downloadSourceCode(on request: Request) throws -> EventLoopFuture<Void> {
        try shellOut(to: "mkdir -p \(self.workingDirectory)")
        
        return request.client
            .get(archiveRequetsURL, headers: context.requestHeader)
            .flatMapThrowing { response -> ByteBuffer? in
                guard response.status == .ok else {
                    request.logger.error("Could not download the .zip from \(archiveRequetsURL)")
                    throw Abort(.internalServerError, reason: "Could not download the .zip archieve from BitBucket")
                }
                
                request.logger.debug("Recieved Zip Archive from Bitbucket (\(response.body?.readableBytes ?? 0) B)")
                return response.body
            }
            .unwrap(or: Abort(.badRequest, reason: "Could not parse the pull request body"))
            .flatMap { byteBuffer in
                request.fileio.writeFile(byteBuffer, at: "\(workingDirectory)/\(pullRequest.commitHash).zip")
            }
            .flatMap {
                do {
                    return try unzipSourceCode(on: request)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
    }
}
