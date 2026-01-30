//
//  PenelopeWidget.swift
//  PenelopeWidgetExtension
//
//  🐙 Widget for monitoring Penelope Gateway
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct GatewayEntry: TimelineEntry {
    let date: Date
    let status: GatewayStatus
    let configuration: ConfigurationAppIntent
}

// MARK: - Timeline Provider

struct GatewayTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = GatewayEntry
    typealias Intent = ConfigurationAppIntent
    
    func placeholder(in context: Context) -> Entry {
        GatewayEntry(
            date: Date(),
            status: GatewayStatus(
                isOnline: true,
                sessionCount: 5,
                totalTokens: 125000,
                model: "Claude Opus",
                lastActivity: Date(),
                error: nil
            ),
            configuration: ConfigurationAppIntent()
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> Entry {
        let status = await fetchStatus()
        return GatewayEntry(date: Date(), status: status, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<Entry> {
        let status = await fetchStatus()
        let entry = GatewayEntry(date: Date(), status: status, configuration: configuration)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func fetchStatus() async -> GatewayStatus {
        do {
            return try await GatewayService.shared.fetchStatus()
        } catch {
            return GatewayStatus(
                isOnline: false,
                sessionCount: 0,
                totalTokens: 0,
                model: "N/A",
                lastActivity: nil,
                error: error.localizedDescription
            )
        }
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Penelope Gateway"
    static var description: IntentDescription = "Monitor your Moltbot Gateway status"
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: GatewayEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Text("🐙")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Penelope")
                        .font(.headline)
                        .foregroundStyle(Color("AccentRed"))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(entry.status.isOnline ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(entry.status.isOnline ? "Online" : "Offline")
                            .font(.caption2)
                            .foregroundStyle(entry.status.isOnline ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            if entry.status.isOnline {
                // Stats
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.status.sessionCount) sessions")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Text(formatTokens(entry.status.totalTokens))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(entry.status.error ?? "Offline")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
            
            // Last update
            if let lastActivity = entry.status.lastActivity {
                Text(timeAgo(lastActivity))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color("BackgroundStart"), Color("BackgroundEnd")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct MediumWidgetView: View {
    let entry: GatewayEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("🐙")
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Penelope Gateway")
                            .font(.headline)
                            .foregroundStyle(Color("AccentRed"))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(entry.status.isOnline ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(entry.status.isOnline ? "Running" : "Offline")
                                .font(.caption)
                                .foregroundStyle(entry.status.isOnline ? .green : .red)
                        }
                    }
                }
                
                Spacer()
                
                if entry.status.isOnline {
                    // Model badge
                    Text(entry.status.model)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AccentBlue").opacity(0.3))
                        .cornerRadius(6)
                }
                
                // Last update
                Text("Updated: \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if entry.status.isOnline {
                Divider()
                    .background(Color("AccentBlue"))
                
                // Right side - Stats
                VStack(spacing: 12) {
                    StatView(label: "SESSIONS", value: "\(entry.status.sessionCount)")
                    StatView(label: "TOKENS", value: formatTokens(entry.status.totalTokens))
                    StatView(label: "ACTIVITY", value: timeAgo(entry.status.lastActivity))
                }
            } else {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                    Text(entry.status.error ?? "Gateway Unreachable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color("BackgroundStart"), Color("BackgroundEnd")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct StatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Helper Functions

func formatTokens(_ tokens: Int) -> String {
    if tokens >= 1_000_000 {
        return String(format: "%.1fM", Double(tokens) / 1_000_000)
    } else if tokens >= 1_000 {
        return String(format: "%.1fK", Double(tokens) / 1_000)
    }
    return "\(tokens)"
}

func timeAgo(_ date: Date?) -> String {
    guard let date = date else { return "Never" }
    
    let interval = Date().timeIntervalSince(date)
    
    if interval < 60 {
        return "Just now"
    } else if interval < 3600 {
        let minutes = Int(interval / 60)
        return "\(minutes)m ago"
    } else if interval < 86400 {
        let hours = Int(interval / 3600)
        return "\(hours)h ago"
    } else {
        let days = Int(interval / 86400)
        return "\(days)d ago"
    }
}

// MARK: - Widget Definition

struct PenelopeWidget: Widget {
    let kind: String = "PenelopeWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: GatewayTimelineProvider()
        ) { entry in
            PenelopeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("🐙 Penelope Gateway")
        .description("Monitor your Moltbot Gateway status")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PenelopeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: GatewayEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    PenelopeWidget()
} timeline: {
    GatewayEntry(
        date: Date(),
        status: GatewayStatus(
            isOnline: true,
            sessionCount: 6,
            totalTokens: 228608,
            model: "Claude Opus",
            lastActivity: Date().addingTimeInterval(-300),
            error: nil
        ),
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Medium", as: .systemMedium) {
    PenelopeWidget()
} timeline: {
    GatewayEntry(
        date: Date(),
        status: GatewayStatus(
            isOnline: true,
            sessionCount: 6,
            totalTokens: 228608,
            model: "Claude Opus",
            lastActivity: Date().addingTimeInterval(-300),
            error: nil
        ),
        configuration: ConfigurationAppIntent()
    )
}

#Preview("Offline", as: .systemMedium) {
    PenelopeWidget()
} timeline: {
    GatewayEntry(
        date: Date(),
        status: GatewayStatus.offline,
        configuration: ConfigurationAppIntent()
    )
}
