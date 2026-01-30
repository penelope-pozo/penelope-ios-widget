//
//  GatewayService.swift
//  PenelopeWidget
//
//  Network service for Gateway API calls
//

import Foundation

// MARK: - Models

struct GatewayStatus {
    let isOnline: Bool
    let sessionCount: Int
    let totalTokens: Int
    let model: String
    let lastActivity: Date?
    let error: String?
    
    static var offline: GatewayStatus {
        GatewayStatus(
            isOnline: false,
            sessionCount: 0,
            totalTokens: 0,
            model: "N/A",
            lastActivity: nil,
            error: "Gateway offline"
        )
    }
}

// MARK: - API Response Models

struct ToolInvokeResponse: Codable {
    let ok: Bool
    let result: ToolResult?
    let error: APIError?
}

struct ToolResult: Codable {
    let details: SessionListDetails?
}

struct SessionListDetails: Codable {
    let count: Int
    let sessions: [Session]
}

struct Session: Codable {
    let key: String
    let model: String?
    let totalTokens: Int?
    let updatedAt: Int64?
}

struct APIError: Codable {
    let type: String
    let message: String
}

// MARK: - Gateway Service

actor GatewayService {
    static let shared = GatewayService()
    
    private init() {}
    
    func fetchStatus(gatewayURL: String? = nil, authToken: String? = nil) async throws -> GatewayStatus {
        let defaults = UserDefaults(suiteName: "group.com.penelope.widget")
        
        let url = gatewayURL ?? defaults?.string(forKey: "gatewayURL") ?? ""
        let token = authToken ?? defaults?.string(forKey: "authToken") ?? ""
        
        guard !url.isEmpty, !token.isEmpty else {
            throw GatewayError.missingConfiguration
        }
        
        guard let endpoint = URL(string: "\(url)/tools/invoke") else {
            throw GatewayError.invalidURL
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let body: [String: Any] = [
            "tool": "sessions_list",
            "action": "json",
            "args": [:]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GatewayError.httpError(httpResponse.statusCode)
        }
        
        let decoded = try JSONDecoder().decode(ToolInvokeResponse.self, from: data)
        
        guard decoded.ok, let details = decoded.result?.details else {
            throw GatewayError.apiError(decoded.error?.message ?? "Unknown error")
        }
        
        return processSessionData(details)
    }
    
    private func processSessionData(_ details: SessionListDetails) -> GatewayStatus {
        var totalTokens = 0
        var model = "N/A"
        var lastActivity: Date? = nil
        
        for session in details.sessions {
            totalTokens += session.totalTokens ?? 0
            
            // Get model from main session
            if session.key == "agent:main:main", let sessionModel = session.model {
                model = formatModelName(sessionModel)
            }
            
            // Track most recent activity
            if let updatedAt = session.updatedAt {
                let date = Date(timeIntervalSince1970: Double(updatedAt) / 1000)
                if lastActivity == nil || date > lastActivity! {
                    lastActivity = date
                }
            }
        }
        
        return GatewayStatus(
            isOnline: true,
            sessionCount: details.count,
            totalTokens: totalTokens,
            model: model,
            lastActivity: lastActivity,
            error: nil
        )
    }
    
    private func formatModelName(_ model: String) -> String {
        let mappings: [String: String] = [
            "claude-opus-4-5": "Claude Opus",
            "claude-sonnet-4": "Claude Sonnet",
            "claude-3-5-sonnet": "Sonnet 3.5",
            "claude-3-opus": "Opus 3",
            "gpt-4": "GPT-4",
            "gpt-4-turbo": "GPT-4 Turbo",
        ]
        
        return mappings[model] ?? model
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

// MARK: - Errors

enum GatewayError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Gateway URL or token not configured"
        case .invalidURL:
            return "Invalid gateway URL"
        case .invalidResponse:
            return "Invalid response from gateway"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}
