# BetaCaller - Project Overview

## 📱 What is BetaCaller?

BetaCaller is a full-featured VoIP calling application built with Flutter, similar to popular apps like Yolla and AlphaCaller. It enables users to make low-cost international calls using Twilio's Voice API.

## 🎯 Key Features

### 1. User Authentication
- Email/password registration
- Secure login with JWT tokens
- Auto-login on app restart
- Profile management

### 2. VoIP Calling
- Make calls to any phone number worldwide
- Twilio Voice SDK integration
- In-call controls (mute, speaker, keypad)
- Call quality indicators
- Real-time call duration tracking

### 3. Contact Management
- Sync device contacts
- Search and filter contacts
- Mark favorites
- Quick call from contact list

### 4. Call History
- Complete call logs
- Filter by call type (incoming/outgoing/missed)
- Display call duration and cost
- Redial functionality
- Delete individual or all history

### 5. Balance & Billing
- Real-time balance display
- Add credits/top-up
- Transaction history
- Per-minute call rates
- Automatic cost calculation

## 📂 Project Structure

```
BetaCaller/
├── lib/
│   ├── main.dart                           # App entry point with Provider setup
│   │
│   ├── models/                             # Data Models
│   │   ├── user_model.dart                 # User data structure
│   │   ├── call_model.dart                 # Call record structure
│   │   └── contact_model.dart              # Contact data structure
│   │
│   ├── providers/                          # State Management (Provider)
│   │   ├── auth_provider.dart              # Authentication state
│   │   ├── call_provider.dart              # Call state & history
│   │   ├── contact_provider.dart           # Contact management
│   │   └── balance_provider.dart           # Balance & transactions
│   │
│   ├── services/                           # Business Logic Layer
│   │   ├── api_service.dart                # Backend API integration
│   │   ├── twilio_service.dart             # Twilio Voice SDK wrapper
│   │   └── database_service.dart           # Local SQLite database
│   │
│   ├── screens/                            # UI Screens
│   │   ├── splash_screen.dart              # Splash/loading screen
│   │   ├── auth/
│   │   │   ├── login_screen.dart           # Login UI
│   │   │   └── register_screen.dart        # Registration UI
│   │   ├── home/
│   │   │   ├── home_screen.dart            # Main screen with bottom nav
│   │   │   └── tabs/
│   │   │       ├── dialer_tab.dart         # Phone dialer interface
│   │   │       ├── contacts_tab.dart       # Contacts list
│   │   │       ├── history_tab.dart        # Call history
│   │   │       └── profile_tab.dart        # User profile & settings
│   │   └── calling/
│   │       └── calling_screen.dart         # Active call interface
│   │
│   └── utils/
│       └── app_theme.dart                  # App-wide theming
│
├── assets/                                 # Static Assets
│   ├── images/                             # Images
│   ├── icons/                              # Icons
│   └── fonts/                              # Custom fonts
│
├── android/                                # Android-specific configuration
├── ios/                                    # iOS-specific configuration
│
├── pubspec.yaml                           # Dependencies & app metadata
├── analysis_options.yaml                  # Linting rules
├── .gitignore                             # Git ignore rules
│
└── Documentation/
    ├── README.md                          # Main documentation
    ├── QUICKSTART.md                      # Quick start guide
    ├── BACKEND_SETUP.md                   # Backend setup guide
    ├── TWILIO_INTEGRATION.md              # Twilio integration guide
    └── PROJECT_OVERVIEW.md                # This file
```

## 🛠 Technology Stack

### Frontend
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider
- **UI Components**: Material Design 3

### Backend (Required - Not Included)
- **Authentication**: JWT-based custom backend
- **Database**: Your choice (PostgreSQL, MySQL, MongoDB)
- **VoIP**: Twilio Voice API

### Local Storage
- **Database**: SQLite (sqflite package)
- **Preferences**: SharedPreferences
- **Data**: Call history, user preferences

### Third-Party Services
- **VoIP**: Twilio Voice SDK
- **Permissions**: permission_handler
- **HTTP**: Dio & http packages

## 🔑 Core Components

### 1. Models (Data Layer)

#### UserModel
```dart
- id: String
- email: String
- phoneNumber: String?
- displayName: String?
- profileImageUrl: String?
- createdAt: DateTime
- lastLoginAt: DateTime?
```

#### CallModel
```dart
- id: String
- contactName: String
- phoneNumber: String
- callType: CallType (outgoing/incoming/missed)
- callStatus: CallStatus
- timestamp: DateTime
- duration: int?
- cost: double?
- twilioCallSid: String?
```

#### ContactModel
```dart
- id: String
- displayName: String
- phoneNumber: String?
- email: String?
- photoUrl: String?
- isFavorite: bool
- lastCallDate: DateTime?
- callCount: int
```

### 2. Providers (State Management)

#### AuthProvider
- Manages user authentication state
- Handles login/register/logout
- Stores JWT token
- Auto-login functionality

#### CallProvider
- Manages active calls
- Stores call history
- Integrates with TwilioService
- Updates call status in real-time

#### ContactProvider
- Loads device contacts
- Search and filter functionality
- Manage favorites
- Sync with local database

#### BalanceProvider
- Tracks user balance
- Handles top-up transactions
- Calculates call costs
- Transaction history

### 3. Services (Business Logic)

#### ApiService
- HTTP client wrapper
- Handles all backend API calls
- Authentication endpoints
- Balance management
- Transaction history

#### TwilioService
- Twilio Voice SDK wrapper
- Initialize calling functionality
- Make/receive calls
- In-call controls (mute, speaker, DTMF)
- Call event handling

#### DatabaseService
- SQLite database wrapper
- Call history persistence
- CRUD operations
- Data migration handling

## 🎨 UI/UX Features

### Design Highlights
- **Modern Material Design 3**
- **Dark mode support**
- **Responsive layouts**
- **Smooth animations**
- **Intuitive navigation**

### Color Scheme
- Primary: Purple (#6C63FF)
- Secondary: Teal (#03DAC6)
- Accent: Pink (#FF6584)
- Background Light: Gray (#F5F5F5)
- Background Dark: Dark Gray (#121212)

### Screens

1. **Splash Screen**
   - App logo
   - Loading indicator
   - Auto-navigation to login/home

2. **Login Screen**
   - Email input
   - Password input
   - Forgot password link
   - Register link

3. **Register Screen**
   - Email input
   - Phone number input
   - Password input
   - Confirm password
   - Terms acceptance

4. **Home Screen (Bottom Navigation)**
   - Dialer tab
   - Contacts tab
   - History tab
   - Profile tab

5. **Dialer Tab**
   - Balance display
   - Number input
   - Dial pad (0-9, *, #)
   - Call button

6. **Calling Screen**
   - Contact avatar
   - Contact name/number
   - Call status
   - Duration timer
   - Controls (mute, speaker, keypad)
   - End call button

7. **Contacts Tab**
   - Search bar
   - Alphabetical list
   - Favorite indicator
   - Quick call button

8. **History Tab**
   - Chronological call list
   - Call type icons
   - Duration and cost
   - Delete options

9. **Profile Tab**
   - User info
   - Balance card
   - Add balance button
   - Settings options
   - Logout

## 📊 Data Flow

### Authentication Flow
```
User Input → AuthProvider → ApiService → Backend
                ↓
        Store Token (SharedPreferences)
                ↓
        Navigate to Home
```

### Call Flow
```
User Dials → Check Balance → CallProvider → TwilioService → Twilio API
                                    ↓
                            Update Call Status
                                    ↓
                            Save to DatabaseService
                                    ↓
                            Deduct from Balance
```

### Contact Sync Flow
```
App Launch → ContactProvider → Device Contacts API
                    ↓
            Filter & Process
                    ↓
            Update UI
```

## 🚀 Getting Started

### For Developers

1. **Clone the project**
2. **Install dependencies**: `flutter pub get`
3. **Run in demo mode**: `flutter run`
4. **Test features** with mock data

### For Production

1. **Set up backend** (see BACKEND_SETUP.md)
2. **Configure Twilio** (see TWILIO_INTEGRATION.md)
3. **Update API endpoints** in `api_service.dart`
4. **Test thoroughly**
5. **Build release version**

## 📱 Platform Support

- ✅ **Android**: Minimum SDK 21 (Android 5.0)
- ✅ **iOS**: Minimum iOS 12.0
- ⚠️ **Web**: Limited support (no VoIP)
- ❌ **Desktop**: Not supported

## 🔒 Security Features

- JWT token authentication
- Secure password storage (backend)
- HTTPS-only API calls
- Token expiration handling
- Permission-based access

## 💰 Monetization Potential

- **Per-minute calling rates**
- **Subscription plans**
- **In-app purchases**
- **Commission on top-ups**
- **Premium features**

## 📈 Scalability Considerations

### Current Implementation
- SQLite for local storage
- Provider for state management
- REST API for backend

### Future Enhancements
- WebSocket for real-time updates
- Cloud sync for call history
- Multi-device support
- Group calling
- Video calls
- SMS/messaging

## 🧪 Testing Strategy

### Unit Tests
- Model serialization
- Provider logic
- Service functions

### Widget Tests
- Screen rendering
- User interactions
- Navigation flow

### Integration Tests
- Complete user flows
- API integration
- Database operations

## 📦 Dependencies Summary

### Core
- `flutter` - Framework
- `provider` - State management
- `get` - Navigation & utilities

### VoIP & Calling
- `twilio_voice` - Twilio integration
- `permission_handler` - Device permissions

### UI
- `flutter_svg` - SVG support
- `country_code_picker` - Country selection
- `intl` - Internationalization

### Data & Storage
- `sqflite` - Local database
- `shared_preferences` - Key-value storage
- `path_provider` - File system paths

### Network
- `http` - HTTP client
- `dio` - Advanced HTTP client

### Utilities
- `crypto` - Cryptographic functions
- `jwt_decoder` - JWT parsing
- `url_launcher` - Open URLs

## 🎓 Learning Resources

This project demonstrates:
- Flutter best practices
- Clean architecture
- State management with Provider
- REST API integration
- Local database usage
- Third-party SDK integration
- Material Design implementation

## 📝 Notes

### Current Status
✅ **Complete UI/UX implementation**
✅ **Full state management**
✅ **Mock data for testing**
✅ **Database structure**
⚠️ **Backend integration needed**
⚠️ **Twilio SDK integration needed**
⚠️ **Payment gateway needed**

### Production Requirements
- Custom backend server
- Twilio account & configuration
- Payment gateway integration
- App store accounts
- Legal documents (ToS, Privacy Policy)

## 🤝 Contributing

This is a template project. Feel free to:
- Fork and customize
- Add new features
- Improve existing code
- Share feedback

## 📄 License

MIT License - Free to use and modify

---

**Built with ❤️ using Flutter**

For questions or support, refer to the documentation files or create an issue in the repository.
