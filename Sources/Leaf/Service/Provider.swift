import Async
import Core
import Dispatch
import Foundation
import Service

/// Used to configure Leaf renderer.
public struct LeafConfig {
    let tags: [String: LeafTag]
    let viewsDir: String
    let fileFactory: LeafRenderer.FileFactory

    public init(
        tags: [String: LeafTag] = defaultTags,
        viewsDir: String = "/",
        fileFactory: @escaping LeafRenderer.FileFactory = File.init
    ) {
        self.tags = tags
        self.viewsDir = viewsDir
        self.fileFactory = fileFactory
    }
}

public final class LeafProvider: Provider {
    /// See Service.Provider.repositoryName
    public static let repositoryName = "leaf"

    public init() {}

    /// See Service.Provider.Register
    public func register(_ services: inout Services) throws {
        services.register(ViewRenderer.self) { container -> LeafRenderer in
            let config = try container.make(LeafConfig.self, for: LeafRenderer.self)
            return LeafRenderer(
                tags: config.tags,
                viewsDir: config.viewsDir,
                fileFactory: config.fileFactory
            )
        }

        services.register { container -> LeafConfig in
            let dir = try container.make(DirectoryConfig.self, for: LeafRenderer.self)
            return LeafConfig(viewsDir: dir.workDir + "Resources/Views")
        }
    }

    /// See Service.Provider.boot
    public func boot(_ container: Container) throws { }
}


// MARK: View

public struct View: Codable {
    /// The view's data.
    public let data: Data

    /// Create a new View
    public init(data: Data) {
        self.data = data
    }

    /// See Encodable.encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    /// See Decodable.decode
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(data: container.decode(Data.self))
    }
}


public protocol ViewRenderer {
    /// Renders a view using the supplied encodable context and worker.
    func make(_ path: String, context: Encodable, on eventLoop: EventLoop) throws -> Future<View>
}

extension ViewRenderer {
    /// Renders a view without a context.
    func make(_ path: String, on eventLoop: EventLoop) throws -> Future<View> {
        return try make(path, context: nil as String?, on: eventLoop)
    }

    /// Renders a view using the supplied dictionary.
    func make(_ path: String, _ context: [String: Encodable], on eventLoop: EventLoop) throws -> Future<View> {
        return try make(path, context: context as Encodable, on: eventLoop)
    }
}