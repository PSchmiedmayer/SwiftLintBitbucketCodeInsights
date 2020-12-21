//
//  PullRequest.swift
//  
//
//  Created by Paul Schmiedmayer on 12/20/20.
//

import Foundation


struct PullRequest: Decodable {
    let branchId: String
    let branchName: String
    let commitHash: String
    let repository: Repository
    
    
    private enum CodingKeys: String, CodingKey {
        case branchId = "id"
        case branchName = "displayId"
        case commitHash = "latestCommit"
        case repository = "repository"
    }
    
    private enum PullRequestKeys: String, CodingKey {
        case fromRef
    }
    
    init(from decoder: Decoder) throws {
        let pullRequestValues = try decoder.container(keyedBy: PullRequestKeys.self)
        let sourceBranchValues = try pullRequestValues.nestedContainer(keyedBy: CodingKeys.self, forKey: .fromRef)
        
        self.branchId = try sourceBranchValues.decode(String.self, forKey: .branchId)
        self.branchName = try sourceBranchValues.decode(String.self, forKey: .branchName)
        self.commitHash = try sourceBranchValues.decode(String.self, forKey: .commitHash)
        self.repository = try sourceBranchValues.decode(Repository.self, forKey: .repository)
    }
}

struct Repository: Decodable {
    let key: String
    let name: String
    let project: Project
    
    private enum CodingKeys: String, CodingKey {
        case key = "slug"
        case name = "name"
        case project = "project"
    }
}

struct Project: Decodable {
    let key: String
    let name: String
}
