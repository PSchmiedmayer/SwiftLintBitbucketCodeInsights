//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import SwiftLintFramework

extension BitbucketEvent {
    func executeSwiftLint(on request: Request) throws -> EventLoopFuture<Void> {
        let configuration = Configuration(configurationFiles: [sourceCodeDirectory + "/.swiftlint.yml"])
        
        var swiftFiles: [SwiftLintFile] = []
        let directoryEnumerator = FileManager.default.enumerator(atPath: sourceCodeDirectory)
        while let path = directoryEnumerator?.nextObject() as? String {
            if configuration.excludedPaths.contains(where: { path.hasPrefix($0) }) {
                continue
            }
            if path.hasSuffix("swift"), let swiftFile = SwiftLintFile(path: sourceCodeDirectory + "/" + path) {
                swiftFiles.append(swiftFile)
            }
        }
        
        var violations: [StyleViolation] = []
        for swiftFile in swiftFiles {
            let storage = RuleStorage()
            violations.append(contentsOf: Linter(file: swiftFile, configuration: configuration)
                                .collect(into: storage)
                                .styleViolations(using: storage))
        }
        
        return try send(violations, on: request)
    }
}
