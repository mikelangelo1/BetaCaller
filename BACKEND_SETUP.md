# Backend Setup Guide

This document explains how to set up your backend server to work with BetaCaller.

## Required Endpoints

### 1. Authentication Endpoints

#### POST /api/auth/register
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "phone_number": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "phone_number": "+1234567890",
    "display_name": "User Name",
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

#### POST /api/auth/login
Login to existing account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "phone_number": "+1234567890",
    "display_name": "User Name",
    "last_login_at": "2025-01-01T00:00:00Z"
  }
}
```

### 2. Balance Endpoints

#### GET /api/balance
Get current user balance.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "balance": 25.50
}
```

#### POST /api/balance/add
Add balance to user account.

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "amount": 20.00
}
```

**Response:**
```json
{
  "success": true,
  "new_balance": 45.50,
  "transaction_id": "txn_123"
}
```

#### GET /api/transactions
Get transaction history.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "transactions": [
    {
      "id": "txn_1",
      "type": "credit",
      "amount": 20.0,
      "description": "Added balance",
      "timestamp": "2025-01-01T00:00:00Z"
    },
    {
      "id": "txn_2",
      "type": "debit",
      "amount": 2.5,
      "description": "Call to +1234567890",
      "timestamp": "2025-01-01T01:00:00Z"
    }
  ]
}
```

### 3. Twilio Endpoints

#### GET /api/twilio/token
Generate Twilio access token for the user.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "token": "twilio_access_token_here",
  "identity": "user_id"
}
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id VARCHAR(255) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20),
  display_name VARCHAR(255),
  profile_image_url TEXT,
  balance DECIMAL(10, 2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  type ENUM('credit', 'debit') NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### Call Records Table (Optional)
```sql
CREATE TABLE call_records (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  call_type ENUM('outgoing', 'incoming', 'missed') NOT NULL,
  duration INT, -- in seconds
  cost DECIMAL(10, 2),
  country_code VARCHAR(5),
  twilio_call_sid VARCHAR(255),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## Twilio Setup

### 1. Create Twilio Account
- Sign up at https://www.twilio.com
- Get your Account SID and Auth Token

### 2. Create TwiML Application
- Go to Console > Voice > TwiML Apps
- Create a new TwiML App
- Note the Application SID

### 3. Buy a Phone Number
- Go to Phone Numbers > Buy a Number
- Purchase a number with Voice capability

### 4. Generate Access Token (Backend Example)

#### Node.js Example
```javascript
const AccessToken = require('twilio').jwt.AccessToken;
const VoiceGrant = AccessToken.VoiceGrant;

function generateToken(identity) {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const apiKey = process.env.TWILIO_API_KEY;
  const apiSecret = process.env.TWILIO_API_SECRET;
  const twimlAppSid = process.env.TWILIO_TWIML_APP_SID;

  const voiceGrant = new VoiceGrant({
    outgoingApplicationSid: twimlAppSid,
    incomingAllow: true,
  });

  const token = new AccessToken(accountSid, apiKey, apiSecret, {
    identity: identity,
    ttl: 3600,
  });

  token.addGrant(voiceGrant);
  return token.toJwt();
}

// Express route example
app.get('/api/twilio/token', authenticate, (req, res) => {
  const token = generateToken(req.user.id);
  res.json({
    success: true,
    token: token,
    identity: req.user.id,
  });
});
```

#### Python Example (Flask)
```python
from twilio.jwt.access_token import AccessToken
from twilio.jwt.access_token.grants import VoiceGrant
import os

def generate_token(identity):
    account_sid = os.environ['TWILIO_ACCOUNT_SID']
    api_key = os.environ['TWILIO_API_KEY']
    api_secret = os.environ['TWILIO_API_SECRET']
    twiml_app_sid = os.environ['TWILIO_TWIML_APP_SID']

    token = AccessToken(account_sid, api_key, api_secret, identity=identity)
    voice_grant = VoiceGrant(
        outgoing_application_sid=twiml_app_sid,
        incoming_allow=True
    )
    token.add_grant(voice_grant)

    return token.to_jwt()

@app.route('/api/twilio/token')
@login_required
def twilio_token():
    token = generate_token(current_user.id)
    return jsonify({
        'success': True,
        'token': token,
        'identity': current_user.id
    })
```

## Call Rate Configuration

### Rate Table Example
```sql
CREATE TABLE call_rates (
  country_code VARCHAR(5) PRIMARY KEY,
  country_name VARCHAR(100),
  rate_per_minute DECIMAL(10, 4),
  currency VARCHAR(3) DEFAULT 'USD'
);

-- Example rates
INSERT INTO call_rates VALUES
  ('+1', 'United States', 0.0120, 'USD'),
  ('+44', 'United Kingdom', 0.0150, 'USD'),
  ('+91', 'India', 0.0080, 'USD'),
  ('+86', 'China', 0.0100, 'USD');
```

## Environment Variables

Create a `.env` file in your backend:

```bash
# Server
PORT=3000
NODE_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=betacaller
DB_USER=your_db_user
DB_PASSWORD=your_db_password

# JWT
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRY=7d

# Twilio
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_API_KEY=your_api_key
TWILIO_API_SECRET=your_api_secret
TWILIO_TWIML_APP_SID=your_twiml_app_sid
TWILIO_PHONE_NUMBER=your_twilio_number

# Payment (if implementing)
STRIPE_SECRET_KEY=your_stripe_key
```

## Security Best Practices

1. **Password Hashing**: Use bcrypt or similar for password hashing
2. **JWT Validation**: Validate JWT tokens on all protected endpoints
3. **Rate Limiting**: Implement rate limiting to prevent abuse
4. **HTTPS Only**: Use SSL/TLS in production
5. **Input Validation**: Validate all user inputs
6. **SQL Injection Prevention**: Use parameterized queries
7. **Balance Verification**: Always verify user balance before calls

## Testing

Use tools like Postman or curl to test your endpoints:

```bash
# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","phone_number":"+1234567890"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Get balance
curl -X GET http://localhost:3000/api/balance \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Deployment

### Recommended Hosting Options
- **Backend**: AWS, Google Cloud, DigitalOcean, Heroku
- **Database**: PostgreSQL, MySQL, MongoDB
- **CDN**: CloudFront, Cloudflare

### Production Checklist
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] SSL certificates installed
- [ ] CORS configured properly
- [ ] Error logging set up
- [ ] Monitoring tools configured
- [ ] Backup strategy in place
- [ ] Load balancing configured (if needed)
