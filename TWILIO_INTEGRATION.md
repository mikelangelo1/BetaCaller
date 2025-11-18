# Twilio Integration Guide for BetaCaller

This guide provides detailed steps to integrate Twilio Voice SDK with your BetaCaller app.

## Overview

Twilio Voice SDK enables you to make and receive VoIP calls directly from your mobile app. This integration uses Twilio's Programmable Voice API.

## Prerequisites

1. Twilio Account (sign up at https://www.twilio.com)
2. Twilio Phone Number with Voice capability
3. TwiML Application
4. Backend server to generate access tokens

## Step 1: Twilio Account Setup

### Create Account
1. Go to https://www.twilio.com/try-twilio
2. Sign up for a free account
3. Verify your email and phone number
4. Note your **Account SID** and **Auth Token** from the Console

### Get API Keys
1. Go to Console > Account > API Keys & Tokens
2. Create a new API Key
3. Save the **API Key SID** and **API Secret** securely

### Buy a Phone Number
1. Navigate to Phone Numbers > Buy a Number
2. Select a number with **Voice** capability
3. Purchase the number
4. Note the phone number (e.g., +1234567890)

### Create TwiML Application
1. Go to Console > Voice > TwiML Apps
2. Click "Create new TwiML App"
3. Set **Friendly Name**: "BetaCaller"
4. Set **Voice Request URL**: `https://your-backend.com/api/twilio/voice`
5. Set **Voice Request Method**: POST
6. Save and note the **Application SID**

## Step 2: Flutter Plugin Setup

The current implementation uses a simplified version. For production, you'll need to integrate the actual Twilio Voice SDK.

### Option 1: Using twilio_voice Plugin

Update `pubspec.yaml`:
```yaml
dependencies:
  twilio_voice: ^0.2.0
```

### Option 2: Using twilio_programmable_voice (More Features)

```yaml
dependencies:
  twilio_programmable_voice: ^0.11.0
```

## Step 3: Update TwilioService

Replace `lib/services/twilio_service.dart` with proper Twilio SDK integration:

```dart
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/twilio_voice.dart';

class TwilioService {
  final TwilioVoice _twilioVoice = TwilioVoice.instance;
  String? _accessToken;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String accessToken) async {
    try {
      _accessToken = accessToken;

      await _twilioVoice.setTokens(accessToken: accessToken);

      // Register device for incoming calls
      await _twilioVoice.registerClient(
        clientIdentifier: 'flutter-client',
        token: accessToken,
      );

      // Set up call listeners
      _twilioVoice.callEventsListener = _handleCallEvents;

      _isInitialized = true;
      debugPrint('Twilio Voice initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Twilio Voice: $e');
      throw Exception('Failed to initialize Twilio Voice: $e');
    }
  }

  void _handleCallEvents(CallEvent event) {
    debugPrint('Call Event: ${event.toString()}');

    switch (event.type) {
      case CallEventType.connected:
        debugPrint('Call connected');
        break;
      case CallEventType.connectFailure:
        debugPrint('Call connection failed');
        break;
      case CallEventType.ringing:
        debugPrint('Call ringing');
        break;
      case CallEventType.declined:
        debugPrint('Call declined');
        break;
      case CallEventType.answer:
        debugPrint('Call answered');
        break;
      case CallEventType.missedCall:
        debugPrint('Missed call');
        break;
      case CallEventType.hangup:
        debugPrint('Call hung up');
        break;
    }
  }

  Future<bool> makeCall(String phoneNumber) async {
    if (!_isInitialized) {
      debugPrint('Twilio not initialized');
      return false;
    }

    try {
      await _twilioVoice.makeCall(
        to: phoneNumber,
        from: 'client:flutter-client',
      );

      debugPrint('Making call to: $phoneNumber');
      return true;
    } catch (e) {
      debugPrint('Error making call: $e');
      return false;
    }
  }

  Future<void> endCall() async {
    try {
      await _twilioVoice.hangUp();
      debugPrint('Call ended');
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  Future<void> muteCall(bool mute) async {
    try {
      await _twilioVoice.muteCall(mute);
      debugPrint('${mute ? 'Muted' : 'Unmuted'} call');
    } catch (e) {
      debugPrint('Error toggling mute: $e');
    }
  }

  Future<void> toggleSpeaker(bool speaker) async {
    try {
      await _twilioVoice.setSpeaker(speaker);
      debugPrint('${speaker ? 'Enabled' : 'Disabled'} speaker');
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  Future<void> sendDigits(String digits) async {
    try {
      await _twilioVoice.sendDigits(digits);
      debugPrint('Sent digits: $digits');
    } catch (e) {
      debugPrint('Error sending digits: $e');
    }
  }

  Future<void> unregister() async {
    try {
      await _twilioVoice.unregisterClient();
      _isInitialized = false;
      debugPrint('Twilio client unregistered');
    } catch (e) {
      debugPrint('Error unregistering: $e');
    }
  }
}
```

## Step 4: Backend Token Generation

### Node.js/Express Example

```javascript
const express = require('express');
const twilio = require('twilio');

const app = express();

const AccessToken = twilio.jwt.AccessToken;
const VoiceGrant = AccessToken.VoiceGrant;

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const apiKey = process.env.TWILIO_API_KEY;
const apiSecret = process.env.TWILIO_API_SECRET;
const twimlAppSid = process.env.TWILIO_TWIML_APP_SID;

app.get('/api/twilio/token', (req, res) => {
  const identity = req.user.id; // From your auth middleware

  const voiceGrant = new VoiceGrant({
    outgoingApplicationSid: twimlAppSid,
    incomingAllow: true,
  });

  const token = new AccessToken(accountSid, apiKey, apiSecret, {
    identity: identity,
    ttl: 3600,
  });

  token.addGrant(voiceGrant);

  res.json({
    success: true,
    token: token.toJwt(),
    identity: identity,
  });
});

// TwiML endpoint for making calls
app.post('/api/twilio/voice', (req, res) => {
  const twiml = new twilio.twiml.VoiceResponse();
  const dial = twiml.dial({ callerId: process.env.TWILIO_PHONE_NUMBER });

  if (req.body.To) {
    dial.number(req.body.To);
  } else {
    twiml.say('Thank you for calling. Goodbye.');
  }

  res.type('text/xml');
  res.send(twiml.toString());
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Step 5: Android Configuration

### Update AndroidManifest.xml

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application>
        <!-- Add this for incoming call notifications -->
        <service
            android:name="com.twilio.voice.VoiceFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

### Update build.gradle

In `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

## Step 6: iOS Configuration

### Update Info.plist

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice calls</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### Update Podfile

In `ios/Podfile`:

```ruby
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Add Twilio Voice SDK
  pod 'TwilioVoice', '~> 6.0'
end
```

Run:
```bash
cd ios && pod install && cd ..
```

## Step 7: Handle Incoming Calls (Optional)

For receiving incoming calls, you need to:

1. Set up Firebase Cloud Messaging (FCM) for push notifications
2. Configure Twilio to send push notifications
3. Handle incoming call notifications in the app

### Firebase Setup

1. Add Firebase to your Flutter project
2. Get FCM token
3. Send FCM token to Twilio

### Update CallProvider

```dart
Future<void> registerForIncomingCalls(String fcmToken) async {
  try {
    await _twilioService.registerForPushNotifications(fcmToken);
  } catch (e) {
    debugPrint('Error registering for incoming calls: $e');
  }
}
```

## Step 8: Testing

### Test Outgoing Calls

1. Run the app
2. Login with your account
3. Enter a phone number
4. Press the call button
5. Verify the call connects

### Test Call Quality

- Check audio quality
- Test mute/unmute
- Test speaker on/off
- Test DTMF tones (keypad during call)

## Troubleshooting

### Common Issues

1. **"Twilio not initialized"**
   - Check if access token is being fetched correctly
   - Verify token is not expired

2. **"Call connection failed"**
   - Check TwiML app configuration
   - Verify Voice Request URL is accessible
   - Check Twilio account balance

3. **No audio during call**
   - Verify microphone permissions
   - Check device audio settings
   - Test on different devices

4. **Cannot receive incoming calls**
   - Verify FCM setup
   - Check push notification permissions
   - Verify Twilio push credentials

## Cost Estimation

Twilio charges for:
- Outbound calls: ~$0.013/min (varies by destination)
- Inbound calls: ~$0.0085/min
- Phone number: ~$1/month

## Production Checklist

- [ ] Implement proper error handling
- [ ] Add call quality monitoring
- [ ] Implement reconnection logic
- [ ] Add call recording (if needed)
- [ ] Set up call analytics
- [ ] Test on multiple devices
- [ ] Implement call rate limiting
- [ ] Add call history sync with backend
- [ ] Implement proper logout (unregister Twilio client)
- [ ] Add network quality indicators

## Resources

- [Twilio Voice SDK Documentation](https://www.twilio.com/docs/voice/sdks)
- [Twilio Flutter Plugin](https://pub.dev/packages/twilio_voice)
- [TwiML Reference](https://www.twilio.com/docs/voice/twiml)
- [Twilio Console](https://console.twilio.com)
