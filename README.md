# 🐙 Penelope iOS Widget

Monitor your Moltbot/Penelope Gateway status directly from your iOS home screen.

![Widget Preview](docs/widget-preview.png)

## Features

- **Real-time Status**: See if your gateway is running or offline
- **Session Count**: Track active agent sessions
- **Token Usage**: Monitor total token consumption
- **Model Info**: See which AI model is active
- **Last Activity**: Know when the gateway was last used

## Two Options

This repository provides **two ways** to get the widget on your iPhone:

### 1. 📱 Scriptable Widget (Quick & Easy)

Best for quick setup without Xcode. Uses the [Scriptable](https://scriptable.app/) app.

**Setup:**

1. Install [Scriptable](https://apps.apple.com/app/scriptable/id1405459188) from the App Store
2. Open Scriptable and tap **+** to create a new script
3. Copy the contents of [`scriptable/PenelopeWidget.js`](scriptable/PenelopeWidget.js)
4. Edit the configuration at the top:
   ```javascript
   const GATEWAY_URL = "https://your-gateway.ts.net";
   const AUTH_TOKEN = "your-auth-token";
   ```
5. Tap ▶️ to test (should show a preview)
6. Go to your home screen → long press → add widget
7. Select Scriptable → choose size → tap the widget to configure
8. Select "PenelopeWidget" script

### 2. 🔨 Native SwiftUI Widget (Full Experience)

A native iOS widget with better performance and system integration.

**Requirements:**

- Xcode 15+
- iOS 17+
- Apple Developer account (for device deployment)

**Setup:**

1. Open `PenelopeWidget/` folder in Xcode
2. Create a new project using File → New → Project → App
3. Add the source files from this repo
4. Configure App Groups:
   - Enable "App Groups" capability for both targets
   - Create group: `group.com.penelope.widget`
5. Build and run on your device
6. Configure the gateway URL and token in the app
7. Add the widget to your home screen

**Project Structure:**

```
PenelopeWidget/
├── PenelopeWidgetApp/           # Main iOS app
│   ├── PenelopeWidgetApp.swift  # App entry point
│   ├── ContentView.swift        # Configuration UI
│   └── Info.plist
├── PenelopeWidgetExtension/     # Widget extension
│   ├── PenelopeWidget.swift     # Widget views & timeline
│   ├── PenelopeWidgetBundle.swift
│   └── Info.plist
└── Shared/                      # Shared code
    ├── GatewayService.swift     # API client
    └── Assets.xcassets/         # Colors & icons
```

## Gateway API

The widget uses the Moltbot Gateway's `/tools/invoke` HTTP endpoint:

```bash
curl -X POST https://your-gateway/tools/invoke \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool": "sessions_list", "action": "json", "args": {}}'
```

This returns session data including:
- Session count
- Per-session token usage
- Model names
- Last activity timestamps

## Widget Sizes

| Size | Info Shown |
|------|------------|
| Small | Status, sessions, tokens |
| Medium | Status, sessions, tokens, model, activity |

## Customization

### Colors

Edit the color assets in `Shared/Assets.xcassets/`:
- `AccentRed` - Title color (#E94560)
- `AccentBlue` - Badge background (#0F3460)
- `BackgroundStart` - Gradient top (#1A1A2E)
- `BackgroundEnd` - Gradient bottom (#16213E)

### Update Frequency

- **Scriptable**: Updates when iOS refreshes widgets (~15-30 min)
- **Native**: Configurable in `GatewayTimelineProvider` (default: 15 min)

## Troubleshooting

### Widget shows "Offline"

1. Verify gateway URL is correct (include `https://`)
2. Check auth token is valid
3. Ensure gateway is running: `moltbot status`
4. Test connection in the app or run the Scriptable script

### Widget not updating

iOS throttles widget updates to save battery. Force refresh:
- Scriptable: Run script manually
- Native: Open the app

### "App Groups" error (Native)

Ensure both the app and widget extension use the same App Group identifier.

## License

MIT License - See [LICENSE](LICENSE)

## Contributing

Pull requests welcome! Please ensure:
- Code follows Swift/JS conventions
- Widget renders correctly at all sizes
- README is updated for new features
