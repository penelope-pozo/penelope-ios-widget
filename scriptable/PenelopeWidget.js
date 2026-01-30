// Penelope Gateway Widget for Scriptable
// 🐙 Monitor your Moltbot/Penelope Gateway status
// 
// Setup:
// 1. Install Scriptable from the App Store
// 2. Create a new script and paste this code
// 3. Update GATEWAY_URL and AUTH_TOKEN below
// 4. Add a Scriptable widget to your home screen
// 5. Select this script

// ============================================
// CONFIGURATION - UPDATE THESE VALUES
// ============================================
const GATEWAY_URL = "https://your-hostname.your-tailnet.ts.net";
const AUTH_TOKEN = "YOUR_GATEWAY_TOKEN_HERE";

// ============================================
// COLOR SCHEME
// ============================================
const COLORS = {
  background: new Color("#1a1a2e"),
  backgroundGradientEnd: new Color("#16213e"),
  title: new Color("#e94560"),
  text: new Color("#ffffff"),
  textMuted: new Color("#a0a0a0"),
  accent: new Color("#0f3460"),
  online: new Color("#4ade80"),
  offline: new Color("#f87171"),
  warning: new Color("#fbbf24"),
};

// ============================================
// DATA FETCHING
// ============================================
async function fetchGatewayStatus() {
  const url = `${GATEWAY_URL}/tools/invoke`;
  const req = new Request(url);
  req.method = "POST";
  req.headers = {
    "Authorization": `Bearer ${AUTH_TOKEN}`,
    "Content-Type": "application/json",
  };
  req.body = JSON.stringify({
    tool: "sessions_list",
    action: "json",
    args: {},
  });
  req.timeoutInterval = 10;

  try {
    const response = await req.loadJSON();
    if (response.ok && response.result && response.result.details) {
      return {
        status: "running",
        sessions: response.result.details.sessions || [],
        count: response.result.details.count || 0,
      };
    }
    return { status: "error", error: "Invalid response" };
  } catch (error) {
    return { status: "offline", error: error.message };
  }
}

function processSessionData(data) {
  if (data.status !== "running") {
    return {
      status: data.status,
      error: data.error,
      sessionCount: 0,
      totalTokens: 0,
      model: "N/A",
      lastActivity: null,
    };
  }

  const sessions = data.sessions;
  let totalTokens = 0;
  let model = "N/A";
  let lastActivity = null;

  for (const session of sessions) {
    totalTokens += session.totalTokens || 0;
    
    // Get the model from the main session
    if (session.key === "agent:main:main" && session.model) {
      model = session.model;
    }
    
    // Track most recent activity
    if (session.updatedAt) {
      if (!lastActivity || session.updatedAt > lastActivity) {
        lastActivity = session.updatedAt;
      }
    }
  }

  return {
    status: "running",
    sessionCount: data.count,
    totalTokens,
    model: formatModelName(model),
    lastActivity,
  };
}

function formatModelName(model) {
  if (!model || model === "N/A") return "N/A";
  
  // Simplify model names
  const mappings = {
    "claude-opus-4-5": "Claude Opus",
    "claude-sonnet-4": "Claude Sonnet",
    "claude-3-5-sonnet": "Sonnet 3.5",
    "claude-3-opus": "Opus 3",
    "gpt-4": "GPT-4",
    "gpt-4-turbo": "GPT-4 Turbo",
  };
  
  return mappings[model] || model.replace(/-/g, " ").replace(/\b\w/g, l => l.toUpperCase());
}

function formatTokens(tokens) {
  if (tokens >= 1000000) {
    return (tokens / 1000000).toFixed(1) + "M";
  } else if (tokens >= 1000) {
    return (tokens / 1000).toFixed(1) + "K";
  }
  return tokens.toString();
}

function formatTimeAgo(timestamp) {
  if (!timestamp) return "Never";
  
  const now = Date.now();
  const diff = now - timestamp;
  
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  
  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  if (minutes > 0) return `${minutes}m ago`;
  return "Just now";
}

// ============================================
// WIDGET RENDERING
// ============================================
function createSmallWidget(data) {
  const widget = new ListWidget();
  
  // Gradient background
  const gradient = new LinearGradient();
  gradient.locations = [0, 1];
  gradient.colors = [COLORS.background, COLORS.backgroundGradientEnd];
  widget.backgroundGradient = gradient;
  
  widget.setPadding(12, 12, 12, 12);
  
  // Header with emoji and status
  const headerStack = widget.addStack();
  headerStack.layoutHorizontally();
  headerStack.centerAlignContent();
  
  const emoji = headerStack.addText("🐙");
  emoji.font = Font.systemFont(24);
  
  headerStack.addSpacer(6);
  
  const titleStack = headerStack.addStack();
  titleStack.layoutVertically();
  
  const title = titleStack.addText("Penelope");
  title.font = Font.boldSystemFont(14);
  title.textColor = COLORS.title;
  
  const statusText = titleStack.addText(data.status === "running" ? "Online" : "Offline");
  statusText.font = Font.mediumSystemFont(10);
  statusText.textColor = data.status === "running" ? COLORS.online : COLORS.offline;
  
  widget.addSpacer(8);
  
  // Main stats
  if (data.status === "running") {
    const statsStack = widget.addStack();
    statsStack.layoutVertically();
    
    const sessionsText = statsStack.addText(`${data.sessionCount} sessions`);
    sessionsText.font = Font.systemFont(12);
    sessionsText.textColor = COLORS.text;
    
    const tokensText = statsStack.addText(`${formatTokens(data.totalTokens)} tokens`);
    tokensText.font = Font.systemFont(12);
    tokensText.textColor = COLORS.textMuted;
  } else {
    const errorText = widget.addText(data.error || "Gateway offline");
    errorText.font = Font.systemFont(11);
    errorText.textColor = COLORS.offline;
  }
  
  widget.addSpacer();
  
  // Last activity
  const lastUpdate = widget.addText(formatTimeAgo(data.lastActivity));
  lastUpdate.font = Font.systemFont(9);
  lastUpdate.textColor = COLORS.textMuted;
  lastUpdate.rightAlignText();
  
  return widget;
}

function createMediumWidget(data) {
  const widget = new ListWidget();
  
  // Gradient background
  const gradient = new LinearGradient();
  gradient.locations = [0, 1];
  gradient.colors = [COLORS.background, COLORS.backgroundGradientEnd];
  widget.backgroundGradient = gradient;
  
  widget.setPadding(14, 16, 14, 16);
  
  // Header row
  const headerStack = widget.addStack();
  headerStack.layoutHorizontally();
  headerStack.centerAlignContent();
  
  const emoji = headerStack.addText("🐙");
  emoji.font = Font.systemFont(32);
  
  headerStack.addSpacer(10);
  
  const titleStack = headerStack.addStack();
  titleStack.layoutVertically();
  
  const title = titleStack.addText("Penelope Gateway");
  title.font = Font.boldSystemFont(16);
  title.textColor = COLORS.title;
  
  const statusRow = titleStack.addStack();
  statusRow.layoutHorizontally();
  statusRow.centerAlignContent();
  
  const statusDot = statusRow.addText("●");
  statusDot.font = Font.systemFont(10);
  statusDot.textColor = data.status === "running" ? COLORS.online : COLORS.offline;
  
  statusRow.addSpacer(4);
  
  const statusLabel = statusRow.addText(data.status === "running" ? "Running" : "Offline");
  statusLabel.font = Font.mediumSystemFont(12);
  statusLabel.textColor = data.status === "running" ? COLORS.online : COLORS.offline;
  
  headerStack.addSpacer();
  
  // Model badge
  if (data.status === "running" && data.model !== "N/A") {
    const modelBadge = headerStack.addStack();
    modelBadge.backgroundColor = COLORS.accent;
    modelBadge.cornerRadius = 6;
    modelBadge.setPadding(4, 8, 4, 8);
    
    const modelText = modelBadge.addText(data.model);
    modelText.font = Font.mediumSystemFont(10);
    modelText.textColor = COLORS.text;
  }
  
  widget.addSpacer(12);
  
  if (data.status === "running") {
    // Stats row
    const statsStack = widget.addStack();
    statsStack.layoutHorizontally();
    
    // Sessions stat
    const sessionsBox = createStatBox("Sessions", data.sessionCount.toString());
    statsStack.addStack().addStack().addStack(); // placeholder for alignment
    statsStack.addSpacer();
    
    // Create stat boxes inline
    const stat1 = statsStack.addStack();
    stat1.layoutVertically();
    stat1.centerAlignContent();
    
    const stat1Label = stat1.addText("SESSIONS");
    stat1Label.font = Font.boldSystemFont(9);
    stat1Label.textColor = COLORS.textMuted;
    
    const stat1Value = stat1.addText(data.sessionCount.toString());
    stat1Value.font = Font.boldSystemFont(22);
    stat1Value.textColor = COLORS.text;
    
    statsStack.addSpacer();
    
    // Divider
    const divider = statsStack.addStack();
    divider.backgroundColor = COLORS.accent;
    divider.size = new Size(1, 40);
    
    statsStack.addSpacer();
    
    // Tokens stat
    const stat2 = statsStack.addStack();
    stat2.layoutVertically();
    stat2.centerAlignContent();
    
    const stat2Label = stat2.addText("TOKENS");
    stat2Label.font = Font.boldSystemFont(9);
    stat2Label.textColor = COLORS.textMuted;
    
    const stat2Value = stat2.addText(formatTokens(data.totalTokens));
    stat2Value.font = Font.boldSystemFont(22);
    stat2Value.textColor = COLORS.text;
    
    statsStack.addSpacer();
    
    // Divider
    const divider2 = statsStack.addStack();
    divider2.backgroundColor = COLORS.accent;
    divider2.size = new Size(1, 40);
    
    statsStack.addSpacer();
    
    // Last activity stat
    const stat3 = statsStack.addStack();
    stat3.layoutVertically();
    stat3.centerAlignContent();
    
    const stat3Label = stat3.addText("ACTIVITY");
    stat3Label.font = Font.boldSystemFont(9);
    stat3Label.textColor = COLORS.textMuted;
    
    const stat3Value = stat3.addText(formatTimeAgo(data.lastActivity));
    stat3Value.font = Font.boldSystemFont(14);
    stat3Value.textColor = COLORS.text;
    
    statsStack.addSpacer();
  } else {
    // Error state
    const errorStack = widget.addStack();
    errorStack.layoutVertically();
    errorStack.centerAlignContent();
    
    const errorTitle = errorStack.addText("⚠️ Gateway Unreachable");
    errorTitle.font = Font.boldSystemFont(14);
    errorTitle.textColor = COLORS.offline;
    
    errorStack.addSpacer(4);
    
    const errorDetail = errorStack.addText(data.error || "Unable to connect to gateway");
    errorDetail.font = Font.systemFont(11);
    errorDetail.textColor = COLORS.textMuted;
  }
  
  widget.addSpacer();
  
  // Footer
  const footerStack = widget.addStack();
  footerStack.layoutHorizontally();
  
  const updateTime = footerStack.addText(`Updated: ${new Date().toLocaleTimeString()}`);
  updateTime.font = Font.systemFont(9);
  updateTime.textColor = COLORS.textMuted;
  
  footerStack.addSpacer();
  
  const gatewayHost = footerStack.addText(new URL(GATEWAY_URL).hostname.split('.')[0]);
  gatewayHost.font = Font.systemFont(9);
  gatewayHost.textColor = COLORS.textMuted;
  
  return widget;
}

// ============================================
// MAIN EXECUTION
// ============================================
async function main() {
  const rawData = await fetchGatewayStatus();
  const data = processSessionData(rawData);
  
  let widget;
  const widgetFamily = config.widgetFamily || "medium";
  
  if (widgetFamily === "small") {
    widget = createSmallWidget(data);
  } else {
    widget = createMediumWidget(data);
  }
  
  // Tap action opens gateway URL
  widget.url = GATEWAY_URL;
  
  // Preview in app
  if (config.runsInApp) {
    if (widgetFamily === "small") {
      widget.presentSmall();
    } else {
      widget.presentMedium();
    }
  }
  
  Script.setWidget(widget);
  Script.complete();
}

await main();
