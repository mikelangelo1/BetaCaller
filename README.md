# BetaCaller - VoIP Calling App

A Flutter-based VoIP calling application similar to Yolla and AlphaCaller, enabling low-cost international calls with Twilio integration.

## Features

- **VoIP Calling**: Make international and domestic calls using Twilio
- **Authentication**: Custom backend authentication system
- **Contact Management**: Sync and manage contacts with favorites
- **Call History**: Track all incoming, outgoing, and missed calls
- **Balance Management**: Add and manage calling credits
- **Beautiful UI**: Modern, clean interface with dark mode support
- **Cost Tracking**: Monitor call costs and transaction history

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **VoIP Service**: Twilio Voice SDK
- **Database**: SQLite (sqflite)
- **HTTP Client**: Dio
- **Authentication**: Custom backend with JWT

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── call_model.dart
│   └── contact_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── call_provider.dart
│   ├── contact_provider.dart
│   └── balance_provider.dart
├── services/                 # Business logic & APIs
│   ├── api_service.dart
│   ├── twilio_service.dart
│   └── database_service.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── tabs/
│   │       ├── dialer_tab.dart
│   │       ├── contacts_tab.dart
│   │       ├── history_tab.dart
│   │       └── profile_tab.dart
│   └── calling/
│       └── calling_screen.dart
└── utils/
    └── app_theme.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Twilio account with Voice API enabled

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd BetaCaller
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure your backend API:
   - Open `lib/services/api_service.dart`
   - Replace `baseUrl` with your actual backend URL

4. Set up Twilio:
   - Create a Twilio account at https://www.twilio.com
   - Get your Account SID and Auth Token
   - Configure your backend to generate Twilio access tokens

5. Run the app:
```bash
flutter run
```

## Backend Requirements

Your backend should implement the following endpoints:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Balance
- `GET /api/balance` - Get user balance
- `POST /api/balance/add` - Add balance
- `GET /api/transactions` - Get transaction history

### Twilio
- `GET /api/twilio/token` - Generate Twilio access token

## Configuration

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
```

### iOS Permissions

Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice calls</string>
<key>NSContactsUsageDescription</key>
<string>We need contacts access to display your contacts</string>
```

## Features Breakdown

### 1. Dialer
- Number pad for entering phone numbers
- Display current balance
- Quick dial functionality
- Balance check before calling

### 2. Contacts
- Sync device contacts
- Search functionality
- Favorite contacts
- Quick call from contacts

### 3. Call History
- View all call records
- Filter by call type (incoming/outgoing/missed)
- Display call duration and cost
- Redial from history
- Delete individual or all history

### 4. Profile & Balance
- View user profile
- Check current balance
- Add balance with quick amounts
- Transaction history
- Settings and logout

## Customization

### Theme
Edit `lib/utils/app_theme.dart` to customize colors and styling.

### Call Rates
Configure call rates in your backend API based on destination country.

## Demo Mode

The app includes mock data for testing without a backend:
- Mock authentication (any email/password works)
- Mock balance data
- Simulated call flow

To disable demo mode, update `lib/services/api_service.dart` to use only real API calls.

## Production Checklist

Before deploying to production:

- [ ] Replace mock API responses with real backend
- [ ] Implement proper Twilio Voice SDK integration
- [ ] Add payment gateway for balance top-up
- [ ] Implement proper error handling
- [ ] Add analytics tracking
- [ ] Set up push notifications for incoming calls
- [ ] Add proper security measures (SSL pinning, etc.)
- [ ] Test on multiple devices and OS versions
- [ ] Implement proper contact syncing
- [ ] Add call recording feature (if required)
- [ ] Implement call quality monitoring

## Twilio Integration Guide

### Backend Token Generation

Your backend should generate Twilio access tokens:

```python
# Python example using Twilio SDK
from twilio.jwt.access_token import AccessToken
from twilio.jwt.access_token.grants import VoiceGrant

def generate_token(identity):
    account_sid = 'your_account_sid'
    api_key = 'your_api_key'
    api_secret = 'your_api_secret'

    token = AccessToken(account_sid, api_key, api_secret, identity=identity)
    voice_grant = VoiceGrant(
        outgoing_application_sid='your_twiml_app_sid',
        incoming_allow=True
    )
    token.add_grant(voice_grant)

    return token.to_jwt()
```

## Troubleshooting

### Common Issues

1. **Calls not connecting**
   - Verify Twilio credentials
   - Check network connectivity
   - Ensure proper permissions are granted

2. **Contacts not loading**
   - Check contact permissions
   - Verify device has contacts

3. **Balance not updating**
   - Check backend API connectivity
   - Verify authentication token

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Support

For support, email support@betacaller.com or create an issue in the repository.

## Acknowledgments

- Twilio for VoIP infrastructure
- Flutter team for the amazing framework
- Open source community for various packages used
