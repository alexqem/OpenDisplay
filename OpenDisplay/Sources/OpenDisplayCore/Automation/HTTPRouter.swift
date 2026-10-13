import Foundation

public struct HTTPParsedRequest: Sendable {
    public let method: String
    public let path: String
    public let body: String?
}

public struct HTTPFormattedResponse: Sendable {
    public let statusCode: Int
    public let statusText: String
    public let bodyJson: String

    public var wireData: Data {
        let payload = bodyJson
        let length = payload.utf8.count
        let header = "HTTP/1.1 \(statusCode) \(statusText)\r\n" +
                     "Content-Type: \(AutomationConstants.contentTypeJson)\r\n" +
                     "Content-Length: \(length)\r\n" +
                     "Server: \(AutomationConstants.serverName)\r\n" +
                     "Connection: close\r\n\r\n"
        return (header + payload).data(using: .utf8) ?? Data()
    }
}

/// Pure functional HTTP request router and serializer (100% testable without sockets)
public enum HTTPRouter {

    /// Parse raw HTTP request string
    public static func parseRawRequest(_ text: String) -> HTTPParsedRequest? {
        let lines = text.components(separatedBy: "\r\n")
        guard let requestLine = lines.first, !requestLine.isEmpty else { return nil }

        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0]).uppercased()
        let path = String(parts[1])

        var body: String?
        if let emptyLineIndex = lines.firstIndex(of: "") {
            let bodyLines = lines[(emptyLineIndex + 1)...]
            let bodyText = bodyLines.joined(separator: "\r\n")
            if !bodyText.isEmpty {
                body = bodyText
            }
        }

        return HTTPParsedRequest(method: method, path: path, body: body)
    }

    /// Helper to enforce required non-empty body in POST requests
    private static func requireBody(_ req: HTTPParsedRequest, onSuccess: (String) -> HTTPFormattedResponse) -> HTTPFormattedResponse {
        guard let body = req.body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return HTTPFormattedResponse(
                statusCode: AutomationConstants.statusBadRequest,
                statusText: "Bad Request",
                bodyJson: "{\"error\":\"Missing body\"}"
            )
        }
        return onSuccess(body)
    }

    /// Dispatch parsed request to appropriate handler
    public static func handleRequest(_ req: HTTPParsedRequest) -> HTTPFormattedResponse {
        switch (req.method, req.path) {
        case ("GET", "/api/v1/status"):
            return HTTPFormattedResponse(
                statusCode: AutomationConstants.statusOk,
                statusText: "OK",
                bodyJson: "{\"status\":\"running\",\"engine\":\"OpenDisplay\",\"arch\":\"arm64\"}"
            )

        case ("GET", "/api/v1/displays"):
            return HTTPFormattedResponse(
                statusCode: AutomationConstants.statusOk,
                statusText: "OK",
                bodyJson: "{\"displays\":[]}"
            )

        case ("POST", "/api/v1/virtual/create"):
            return requireBody(req) { _ in
                HTTPFormattedResponse(
                    statusCode: AutomationConstants.statusCreated,
                    statusText: "Created",
                    bodyJson: "{\"status\":\"created\"}"
                )
            }

        case ("POST", "/api/v1/displays/mirror"):
            return requireBody(req) { _ in
                HTTPFormattedResponse(
                    statusCode: AutomationConstants.statusOk,
                    statusText: "OK",
                    bodyJson: "{\"status\":\"mirror_configured\"}"
                )
            }

        case ("POST", "/api/v1/displays/rotate"):
            return requireBody(req) { _ in
                HTTPFormattedResponse(
                    statusCode: AutomationConstants.statusOk,
                    statusText: "OK",
                    bodyJson: "{\"status\":\"rotation_configured\"}"
                )
            }

        case ("POST", "/api/v1/displays/power"):
            return requireBody(req) { _ in
                HTTPFormattedResponse(
                    statusCode: AutomationConstants.statusOk,
                    statusText: "OK",
                    bodyJson: "{\"status\":\"power_state_updated\"}"
                )
            }

        case ("GET", "/api/v1/presets"):
            return HTTPFormattedResponse(
                statusCode: AutomationConstants.statusOk,
                statusText: "OK",
                bodyJson: "{\"presets\":[]}"
            )

        default:
            return HTTPFormattedResponse(
                statusCode: AutomationConstants.statusNotFound,
                statusText: "Not Found",
                bodyJson: "{\"error\":\"Route not found\"}"
            )
        }
    }
}
