import Vapor
import ShellOut

#if DEBUG
var env = try Environment.detect(arguments: [CommandLine.arguments.first ?? ".", "serve", "--env", "development", "--hostname", "0.0.0.0", "--port", "8080"])
#else
var env = try Environment.detect(arguments: [CommandLine.arguments.first ?? ".", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"])
#endif

try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer {
    app.shutdown()
}

let context = Context.parseOrExit()
app.logger.logLevel = .trace

app.post { request in
    try BitbucketEvent
        .create(from: request)
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<Void> in
            request.logger.info("Parsed webhook request: \(bitbucketEvent.type)")
            return try bitbucketEvent.performSwiftLintBotActions(on: request)
                .map {
                    request.logger.info("Done ✅")
                }
        }
        .transform(to: "Done ✅")
}

try app.run()
