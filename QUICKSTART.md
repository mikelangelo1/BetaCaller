# Quick Start Guide

Get BetaCaller up and running in minutes!

## Prerequisites

- Flutter SDK 3.0+ installed ([Get Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or Xcode
- A code editor (VS Code recommended)

## Installation

### 1. Check Flutter Installation

```bash
flutter doctor
```

Make sure all checkmarks are green. If not, follow the instructions to fix issues.

### 2. Get Dependencies

```bash
cd BetaCaller
flutter pub get
```

### 3. Run in Demo Mode

The app includes mock data for testing without a backend:

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For a specific device
flutter devices
flutter run -d <device_id>
```

### 4. Test the App

**Demo Credentials:**
- Email: Any email (e.g., demo@example.com)
- Password: Any password (e.g., password123)

The app will work in demo mode with:
- Mock authentication
- Sample contacts
- Simulated calls
- Mock balance ($25.50)

## Project Structure

```
BetaCaller/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── providers/             # State management
│   ├── services/              # API & Business logic
│   ├── screens/               # UI screens
│   └── utils/                 # Utilities & themes
├── assets/                    # Images, icons, fonts
├── android/                   # Android-specific files
├── ios/                       # iOS-specific files
├── pubspec.yaml              # Dependencies
├── README.md                 # Main documentation
├── BACKEND_SETUP.md          # Backend setup guide
└── TWILIO_INTEGRATION.md     # Twilio integration guide
```

## Key Features Implemented

✅ **Authentication**
- Login screen
- Registration screen
- JWT token storage
- Auto-login on app restart

✅ **Dialer**
- Number pad
- Direct dialing
- Balance display
- Call initiation

✅ **Contacts**
- Contact list
- Search functionality
- Favorites
- Quick call

✅ **Call History**
- View all calls
- Call details (duration, cost)
- Delete history
- Redial functionality

✅ **Profile & Balance**
- User profile
- Balance management
- Add credits
- Transaction history
- Logout

## Next Steps

### For Production Use

1. **Set up Backend** (See BACKEND_SETUP.md)
   - Deploy backend server
   - Configure database
   - Set up authentication

2. **Integrate Twilio** (See TWILIO_INTEGRATION.md)
   - Create Twilio account
   - Configure TwiML app
   - Implement real calling

3. **Update API Endpoints**
   - Edit `lib/services/api_service.dart`
   - Replace `baseUrl` with your backend URL
   - Remove mock functions

4. **Configure App**
   - Update app name in `pubspec.yaml`
   - Add app icon
   - Update splash screen
   - Configure app signing

## Common Commands

```bash
# Run app
flutter run

# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Run tests
flutter test

# Check for errors
flutter analyze
```

## Customization

### Change App Name

1. **Android**: Edit `android/app/src/main/AndroidManifest.xml`
   ```xml
   <application android:label="Your App Name">
   ```

2. **iOS**: Edit `ios/Runner/Info.plist`
   ```xml
   <key>CFBundleName</key>
   <string>Your App Name</string>
   ```

### Change App Colors

Edit `lib/utils/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF6C63FF);
static const Color secondaryColor = Color(0xFF03DAC6);
```

### Add App Icon

1. Replace `assets/icons/app_icon.png` with your icon
2. Use flutter_launcher_icons package:
   ```bash
   flutter pub add dev:flutter_launcher_icons
   flutter pub run flutter_launcher_icons
   ```

## Testing

### Unit Tests (Coming Soon)
```bash
flutter test
```

### Integration Tests (Coming Soon)
```bash
flutter drive --target=test_driver/app.dart
```

## Build for Release

### Android

```bash
# Generate release APK
flutter build apk --release

# Generate App Bundle (recommended for Play Store)
flutter build appbundle --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`
AAB location: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
# Generate iOS build
flutter build ios --release
```

Then open Xcode:
```bash
open ios/Runner.xcworkspace
```

Archive and upload to App Store.

## Troubleshooting

### "Package not found" error
```bash
flutter clean
flutter pub get
```

### "Build failed" error
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter run
```

### "SDK version" error
- Check `pubspec.yaml` SDK version
- Update Flutter: `flutter upgrade`

### Permissions issues
- Check AndroidManifest.xml (Android)
- Check Info.plist (iOS)

## Support & Resources

- **Documentation**: See README.md for full documentation
- **Backend Setup**: See BACKEND_SETUP.md
- **Twilio Integration**: See TWILIO_INTEGRATION.md
- **Flutter Docs**: https://flutter.dev/docs
- **Twilio Docs**: https://www.twilio.com/docs

## What's Included

✅ Complete UI/UX
✅ State management with Provider
✅ Local database (SQLite)
✅ Mock API for testing
✅ Call history tracking
✅ Contact management
✅ Balance management
✅ Modern, clean design
✅ Dark mode support
✅ Responsive layouts

## What You Need to Add

- [ ] Real backend API
- [ ] Twilio Voice SDK integration
- [ ] Payment gateway
- [ ] Push notifications
- [ ] Analytics
- [ ] Crash reporting
- [ ] App icon and splash screen
- [ ] Terms of service
- [ ] Privacy policy

## Development Tips

1. **Hot Reload**: Press `r` in terminal while app is running
2. **Hot Restart**: Press `R` in terminal
3. **Debug Mode**: Use Flutter DevTools
4. **Logging**: Check `debugPrint()` statements in console

## Ready to Deploy?

### Pre-deployment Checklist

- [ ] Test on multiple devices
- [ ] Test in release mode
- [ ] Remove debug logs
- [ ] Update app version
- [ ] Generate release builds
- [ ] Test payment flow
- [ ] Review app permissions
- [ ] Prepare app store assets
- [ ] Write app description
- [ ] Create privacy policy

### App Store Requirements

**Android (Google Play)**
- App icon (512x512px)
- Feature graphic (1024x500px)
- Screenshots (phone and tablet)
- App description
- Privacy policy URL

**iOS (App Store)**
- App icon (1024x1024px)
- Screenshots (various sizes)
- App description
- Privacy policy URL
- App review information

## License

This project is open source and available under the MIT License.

## Questions?

Read the documentation:
- README.md - Main documentation
- BACKEND_SETUP.md - Backend setup
- TWILIO_INTEGRATION.md - Twilio integration

Happy coding! 🚀
