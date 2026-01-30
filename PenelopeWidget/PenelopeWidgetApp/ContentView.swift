//
//  ContentView.swift
//  PenelopeWidget
//
//  Main app view for configuration
//

import SwiftUI

struct ContentView: View {
    @AppStorage("gatewayURL", store: UserDefaults(suiteName: "group.com.penelope.widget"))
    private var gatewayURL: String = "https://your-hostname.your-tailnet.ts.net"
    
    @AppStorage("authToken", store: UserDefaults(suiteName: "group.com.penelope.widget"))
    private var authToken: String = ""
    
    @State private var testStatus: String = ""
    @State private var isTesting: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Label("Gateway Configuration", systemImage: "server.rack")) {
                    TextField("Gateway URL", text: $gatewayURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Auth Token", text: $authToken)
                        .textContentType(.password)
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(isTesting || gatewayURL.isEmpty || authToken.isEmpty)
                    
                    if !testStatus.isEmpty {
                        HStack {
                            Image(systemName: testStatus.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testStatus.contains("Success") ? .green : .red)
                            Text(testStatus)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("🐙")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Penelope Widget")
                                .font(.headline)
                            Text("Monitor your Moltbot Gateway")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Link(destination: URL(string: "https://github.com/penelope-pozo/penelope-ios-widget")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                }
                
                Section(header: Text("Instructions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(number: 1, text: "Enter your Gateway URL above")
                        InstructionRow(number: 2, text: "Enter your auth token")
                        InstructionRow(number: 3, text: "Test the connection")
                        InstructionRow(number: 4, text: "Add widget to your home screen")
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("🐙 Penelope")
        }
    }
    
    func testConnection() {
        isTesting = true
        testStatus = ""
        
        Task {
            do {
                let status = try await GatewayService.shared.fetchStatus(
                    gatewayURL: gatewayURL,
                    authToken: authToken
                )
                await MainActor.run {
                    testStatus = "Success! \(status.sessionCount) sessions, \(formatTokens(status.totalTokens)) tokens"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testStatus = "Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
    
    func formatTokens(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.1fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ContentView()
}
