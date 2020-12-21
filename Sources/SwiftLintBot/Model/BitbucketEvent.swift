//
//  BitbucketEvent.swift
//  
//
//  Created by Paul Schmiedmayer on 12/20/20.
//

import Vapor

struct BitbucketEvent {
    /// Classifies a request from Bitbucket into different event types
    ///
    /// Source: [https://confluence.atlassian.com](https://confluence.atlassian.com/bitbucketserver076/event-payload-1026535078.html)
    enum BitbucketEventType: String {
        /// Used to test a webhook when seeting up a webhook in Bitbucket
        case diagnostics = "diagnostics:ping"
        /// A new pull request is opened
        case pullRequestOpened = "pr:opened"
        /// A pull request's source branch is updated
        case pullRequestSourceBranchUpdated = "pr:from_ref_updated"
        /// The pull request has been updated
        case pullRequestModified = "pr:modified"
    }
    
    struct PullRequestEventContent: Decodable {
        let actor: Actor
        let pullRequest: PullRequest
    }
    
    
    let type: BitbucketEventType
    private let content: PullRequestEventContent
    
    var workingDirectory: String {
        "\(app.directory.workingDirectory)/\(project.key)/\(repository.key)"
    }
    
    var sourceCodeDirectory: String {
        "\(workingDirectory)/\(pullRequest.commitHash)"
    }
    
    var pullRequest: PullRequest {
        content.pullRequest
    }
    
    var project: Project {
        content.pullRequest.repository.project
    }
    
    var repository: Repository {
        content.pullRequest.repository
    }
}

extension BitbucketEvent {
    static func create(from request: Request) throws -> EventLoopFuture<BitbucketEvent> {
        guard let eventKey = request.headers.first(name: "X-Event-Key") else {
            throw Abort(.badRequest, reason: "Missing an \"X-Event-Key\" header value from the BitBucket request")
        }
        
        guard let type = BitbucketEventType(rawValue: eventKey) else {
            throw Abort(.badRequest, reason: "Unexpected \"X-Event-Key\" header value named \"\(eventKey)\"")
        }
        
        return request.body
            .collect()
            .unwrap(or: Abort(.badRequest, reason: "Could not parse the pull request body"))
            .mapThrowing { byteBuffer in
                guard let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) else {
                    throw Abort(.badRequest, reason: "Could not parse the pull request body")
                }
                
                return try JSONDecoder().decode(PullRequestEventContent.self, from: data)
            }
            .map {pullRequestEventContent in
                BitbucketEvent(type: type, content: pullRequestEventContent)
            }
    }
}
