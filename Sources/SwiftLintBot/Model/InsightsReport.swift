//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/23/20.
//

import Vapor
import SwiftLintFramework


struct InsightsReport: Content {
    enum InsightsReportResult: String, Codable {
        case pass = "PASS"
        case fail = "FAIL"
    }
    
    enum InsightsReportData: Codable {
        case bool(title: String, Bool)
        case date(title: String, Date)
        case duration(title: String, milliseconds: Int)
        case link(title: String, URL)
        case number(title: String, Int)
        case decimalNumber(title: String, Double)
        case percentage(title: String, Double)
        case text(title: String, String)
        
        enum CodingKeys: String, CodingKey {
            case title
            case value
            case type
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let title = try values.decode(String.self, forKey: .title)
            let type = try values.decode(String?.self, forKey: .type)
            
            switch type {
            case "BOOLEAN":
                self = .bool(title: title, try values.decode(Bool.self, forKey: .value))
            case "DATE":
                self = .date(title: title, try values.decode(Date.self, forKey: .value))
            case "DURATION":
                self = .duration(title: title, milliseconds: try values.decode(Int.self, forKey: .value))
            case "LINK":
                self = .link(title: title, try values.decode(URL.self, forKey: .value))
            case "NUMBER":
                self = .decimalNumber(title: title, try values.decode(Double.self, forKey: .value))
            case "PERCENTAGE":
                self = .percentage(title: title, try values.decode(Double.self, forKey: .value))
            default:
                self = .text(title: title, try values.decode(String.self, forKey: .value))
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            func encode<T: Encodable>(type: String, title: String, value: T) throws {
                try container.encode(type, forKey: .type)
                try container.encode(title, forKey: .title)
                try container.encode(value, forKey: .value)
            }
            
            switch self {
            case let .bool(title, value):
                try encode(type: "BOOLEAN", title: title, value: value)
            case let .date(title, value):
                try encode(type: "DATE", title: title, value: value)
            case let .duration(title, value):
                try encode(type: "DURATION", title: title, value: value)
            case let .link(title, value):
                try encode(type: "LINK", title: title, value: value)
            case let .number(title, value):
                try encode(type: "NUMBER", title: title, value: value)
            case let .decimalNumber(title, value):
                try encode(type: "NUMBER", title: title, value: value)
            case let .percentage(title, value):
                try encode(type: "PERCENTAGE", title: title, value: value)
            case let .text(title, value):
                try encode(type: "TEXT", title: title, value: value)
            }
        }
    }
    
    let title: String
    let details: String?
    let result: InsightsReportResult
    var data: [InsightsReportData] = []
    var reporter: String? = "SwiftLint Bitbucket Code Insights"
    var link: String? = "https://github.com/PSchmiedmayer/SwiftLintBitbucketCodeInsights"
    var logoURL: String? = "https://avatars3.githubusercontent.com/u/7575099"
}

extension InsightsReport {
    init(_ violations: [StyleViolation]) {
        let errors = violations.reduce(0) { errors, violation in
            errors + (violation.severity == .error ? 1 : 0)
        }
        
        let warnings = violations.reduce(0) { warnings, violation in
            warnings + (violation.severity == .warning ? 1 : 0)
        }
        
        self.title = "SwiftLint Report"
        self.result = violations.isEmpty ? .pass : .fail
        self.details = "This commit has \(errors) errors and \(warnings) warnings as reported by SwiftLint."
        
        let violationGroups = Dictionary(grouping: violations, by: { $0.ruleDescription })
        self.data = violationGroups.map { key, values in
            .number(title: "\(key) Violations", values.count)
        }
    }
}
