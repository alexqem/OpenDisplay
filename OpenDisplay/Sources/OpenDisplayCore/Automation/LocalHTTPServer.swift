#if os(macOS) && arch(arm64)
import Foundation
import Network

/// Embedded lightweight HTTP REST automation server
public final class LocalHTTPServer: @unchecked Sendable {
    private let listener: NWListener
    public let port: UInt16

    public init(port: UInt16 = AutomationConstants.defaultHttpPort) throws {
        self.port = port
        let params = NWParameters.tcp
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            throw POSIXError(.EINVAL)
        }
        self.listener = try NWListener(using: params, on: endpointPort)

        self.listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        self.listener.start(queue: .main)
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: AutomationConstants.maxRequestBodyLength) { data, _, _, _ in
            guard let data = data,
                  let text = String(data: data, encoding: .utf8),
                  let request = HTTPRouter.parseRawRequest(text) else {
                connection.cancel()
                return
            }

            let response = HTTPRouter.handleRequest(request)
            connection.send(content: response.wireData, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }

    public func stop() {
        listener.cancel()
    }

    deinit {
        listener.cancel()
    }
}
#endif
