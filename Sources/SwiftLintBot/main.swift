import Vapor
import ShellOut

var env = Environment(name: "custom", arguments: ["serve"])
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer {
    app.shutdown()
}

let context = Context.parseOrExit()


app.post { request in
    try BitbucketEvent
        .create(from: request)
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<Void> in
            request.logger.info("Parsed webhook request: \(bitbucketEvent.type)")
            return try bitbucketEvent.performSwiftLintBotActions(on: request)
        }
        .transform(to: "Done ✅")
}

try app.run()
