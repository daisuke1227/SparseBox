import SwiftUI

struct BLSandboxEscapeView: View {
    @State private var serverRunning = false
    @State private var blServer = BLSandboxEscape()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var localIP: String = ""

    var body: some View {
        Form {
            Section {
                if serverRunning {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Server Running")
                            .bold()
                    }
                } else {
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                        Text("Server Stopped")
                    }
                }
            } header: {
                Text("Server Status")
            }

            Section {
                Button(serverRunning ? "Stop Server" : "Start Server") {
                    toggleServer()
                }
                .foregroundColor(serverRunning ? .red : .blue)
            }

            if serverRunning && !localIP.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Server URL:")
                            .font(.headline)
                        Text("http://\(localIP):\(BLSandboxEscape.PORT)")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(6)
                    }
                } header: {
                    Text("Connection Details")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Files:")
                            .font(.headline)
                        ForEach(blServer.filesToServe, id: \.self) { file in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                Text(file)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                } header: {
                    Text("Exploit Files")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("Compatibility:")
                            .font(.headline)
                        Text("• iOS 26.1 and below")
                        Text("• Patched in iOS 26.2+")
                    }

                    Divider()

                    Group {
                        Text("How it works:")
                            .font(.headline)
                        Text("This exploit uses two stages to escape the sandbox:")

                        Text("Stage 1 - itunesstored:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text("Delivers crafted BLDatabaseManager.sqlite to a writable container.")

                        Text("Stage 2 - bookassetd:")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text("Downloads attacker-controlled EPUB payloads to arbitrary file paths.")
                    }

                    Divider()

                    Group {
                        Text("Writable Paths:")
                            .font(.headline)
                        Text("• /private/var/containers/Shared/SystemGroup/.../Library/Caches/")
                            .font(.system(.caption, design: .monospaced))
                        Text("• /private/var/mobile/Library/FairPlay/")
                            .font(.system(.caption, design: .monospaced))
                        Text("• /private/var/mobile/Media/")
                            .font(.system(.caption, design: .monospaced))
                    }

                    Divider()

                    Group {
                        Text("Usage:")
                            .font(.headline)
                        Text("1. Start the server using the button above")
                        Text("2. Connect your iOS device to the same WiFi network")
                        Text("3. Access the server URL from your device")
                        Text("4. Download and place the files according to the exploit instructions")
                        Text("5. The exploit will modify MobileGestalt.plist to spoof device type")
                    }
                }
            } header: {
                Text("Information")
            } footer: {
                Text("⚠️ For educational and research purposes only. This vulnerability has been patched in iOS 26.2+.")
            }
        }
        .navigationTitle("BL Sandbox Escape")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Server Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            localIP = BLSandboxEscape.getLocalIPAddress() ?? "Unable to detect IP"
        }
        .onDisappear {
            if serverRunning {
                blServer.stopServer()
                serverRunning = false
            }
        }
    }

    private func toggleServer() {
        if serverRunning {
            blServer.stopServer()
            serverRunning = false
        } else {
            do {
                try blServer.startServer()
                serverRunning = true
                localIP = BLSandboxEscape.getLocalIPAddress() ?? "Unable to detect IP"
            } catch {
                alertMessage = "Failed to start server: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
