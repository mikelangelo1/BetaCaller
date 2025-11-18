# BetaCaller Backend - Complete Setup Guide

## 🎉 Backend Successfully Created!

A production-ready TypeScript backend with Clerk authentication and PostgreSQL has been built for your BetaCaller VoIP app.

## 📊 What Was Built

### Technology Stack
- **Language**: TypeScript 5.x
- **Framework**: Express.js
- **Database**: PostgreSQL with Sequelize ORM
- **Authentication**: Clerk (no passwords to manage!)
- **VoIP**: Twilio Voice SDK
- **Deployment**: Docker + Docker Compose

### Files Created: 24 TypeScript Files + Config

#### Configuration (5 files)
- `package.json` - Dependencies and scripts
- `tsconfig.json` - TypeScript configuration
- `.env.example` - Environment variables template
- `Dockerfile` - Docker build configuration
- `docker-compose.yml` - Multi-container setup

#### Source Code (24 TypeScript files)

**Core** (1 file)
- `src/index.ts` - Application entry point

**Configuration** (2 files)
- `src/config/database.ts` - PostgreSQL/Sequelize setup
- `src/config/clerk.ts` - Clerk SDK configuration

**Models** (4 files)
- `src/models/User.ts` - User model with Clerk integration
- `src/models/Transaction.ts` - Balance transactions
- `src/models/CallRecord.ts` - Call history records
- `src/models/CallRate.ts` - International calling rates

**Middleware** (3 files)
- `src/middleware/clerkAuth.ts` - Clerk authentication
- `src/middleware/errorHandler.ts` - Centralized error handling
- `src/middleware/rateLimiter.ts` - API rate limiting

**Services** (3 files)
- `src/services/balance.service.ts` - Balance management logic
- `src/services/call.service.ts` - Call management logic
- `src/services/twilio.service.ts` - Twilio integration

**Controllers** (4 files)
- `src/controllers/auth.controller.ts` - User authentication
- `src/controllers/balance.controller.ts` - Balance operations
- `src/controllers/call.controller.ts` - Call operations
- `src/controllers/twilio.controller.ts` - Twilio webhooks

**Routes** (5 files)
- `src/routes/auth.routes.ts` - Auth endpoints
- `src/routes/balance.routes.ts` - Balance endpoints
- `src/routes/call.routes.ts` - Call endpoints
- `src/routes/twilio.routes.ts` - Twilio endpoints
- `src/routes/user.routes.ts` - User endpoints

**Types & Utils** (2 files)
- `src/types/index.ts` - TypeScript interfaces
- `src/utils/logger.ts` - Winston logger setup

## 🚀 Quick Start

### Option 1: Docker (Recommended)

```bash
cd backend

# Copy environment file
cp .env.example .env

# Update .env with your credentials

# Start everything
docker-compose up -d

# View logs
docker-compose logs -f api

# API is now running at http://localhost:3000
```

### Option 2: Local Development

```bash
cd backend

# Run setup script
./setup.sh

# Update .env with your credentials

# Create PostgreSQL database
createdb betacaller

# Start development server
npm run dev

# API is now running at http://localhost:3000
```

## 🔑 Required API Keys

### 1. Clerk (Authentication)

**Get your keys:**
1. Go to https://clerk.com
2. Sign up / Login
3. Create a new application
4. Go to "API Keys" in dashboard
5. Copy:
   - Secret Key (starts with `sk_test_`)
   - Publishable Key (starts with `pk_test_`)

**Add to .env:**
```env
CLERK_SECRET_KEY=sk_test_your_key_here
CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
```

### 2. Twilio (VoIP Calling)

**Get your credentials:**
1. Go to https://twilio.com
2. Sign up / Login
3. From Console Dashboard, get:
   - Account SID
   - Auth Token
4. Create API Keys:
   - Console → Account → API Keys
   - Create New API Key
   - Save API Key and API Secret
5. Create TwiML Application:
   - Console → Voice → TwiML Apps
   - Create new TwiML App
   - Voice Request URL: `https://your-api.com/api/twilio/voice`
   - Save Application SID
6. Buy a phone number:
   - Console → Phone Numbers → Buy a Number
   - Select number with Voice capability

**Add to .env:**
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_API_KEY=SKxxxxxxxxxxxxx
TWILIO_API_SECRET=your_api_secret
TWILIO_TWIML_APP_SID=APxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890
```

## 📡 API Endpoints

All endpoints are prefixed with `/api`

### Authentication (Clerk-based)

```
GET    /api/auth/profile          Get user profile
PUT    /api/auth/profile          Update profile
DELETE /api/auth/account          Delete account
```

### Balance Management

```
GET    /api/balance               Get current balance
POST   /api/balance/add           Add balance
GET    /api/balance/transactions  Transaction history
```

### Call Management

```
POST   /api/calls                 Create call record
PUT    /api/calls/:id/end         End call & calculate cost
GET    /api/calls/history         Get call history
GET    /api/calls/statistics      Get call stats
DELETE /api/calls/:id             Delete call record
```

### Twilio Integration

```
GET    /api/twilio/token          Get Twilio access token
POST   /api/twilio/voice          Voice webhook (Twilio)
POST   /api/twilio/status         Status webhook (Twilio)
```

### Health Check

```
GET    /health                    Server health status
```

## 🔐 Authentication Flow

### How Clerk Works

1. **Flutter App**: User signs up/logs in via Clerk SDK
2. **Clerk**: Issues JWT token to client
3. **API Requests**: Client sends token in `Authorization: Bearer <token>` header
4. **Backend**: Validates token with Clerk
5. **Database**: Creates/updates user record automatically

### Example Request

```bash
curl -H "Authorization: Bearer <clerk_token>" \
     http://localhost:3000/api/balance
```

## 💾 Database Schema

### Users Table
```typescript
{
  id: UUID
  clerkId: string (unique, from Clerk)
  email: string
  phoneNumber?: string
  displayName?: string
  profileImageUrl?: string
  balance: decimal(10,2)
  lastLoginAt?: timestamp
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
}
```

### Transactions Table
```typescript
{
  id: UUID
  userId: UUID (foreign key)
  type: 'credit' | 'debit'
  amount: decimal(10,2)
  description?: string
  referenceType?: string
  referenceId?: string
  balanceBefore?: decimal(10,2)
  balanceAfter?: decimal(10,2)
  metadata?: json
  createdAt: timestamp
}
```

### Call Records Table
```typescript
{
  id: UUID
  userId: UUID (foreign key)
  phoneNumber: string
  contactName?: string
  callType: 'outgoing' | 'incoming' | 'missed'
  callStatus: enum
  duration?: number (seconds)
  cost?: decimal(10,4)
  countryCode?: string
  twilioCallSid?: string
  startTime?: timestamp
  endTime?: timestamp
  metadata?: json
  createdAt: timestamp
}
```

## 🧪 Testing the API

### Health Check
```bash
curl http://localhost:3000/health
```

### Get Twilio Token (with Clerk auth)
```bash
curl -H "Authorization: Bearer <clerk_token>" \
     http://localhost:3000/api/twilio/token
```

### Get Balance
```bash
curl -H "Authorization: Bearer <clerk_token>" \
     http://localhost:3000/api/balance
```

### Add Balance
```bash
curl -X POST \
     -H "Authorization: Bearer <clerk_token>" \
     -H "Content-Type: application/json" \
     -d '{"amount": 20.00}' \
     http://localhost:3000/api/balance/add
```

## 🔄 Connecting Flutter App

### Update Flutter App

1. **Install Clerk Flutter Package:**
```yaml
dependencies:
  clerk_flutter: ^latest_version
```

2. **Initialize Clerk:**
```dart
import 'package:clerk_flutter/clerk_flutter.dart';

await Clerk.initialize(
  publishableKey: 'pk_test_your_key'
);
```

3. **Update API Service:**
Replace the custom JWT auth with Clerk token:

```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://your-backend-url:3000/api';

  Future<String?> _getToken() async {
    // Get Clerk session token
    return await Clerk.session?.getToken();
  }

  Future<Map<String, dynamic>> getBalance() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/balance'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    return jsonDecode(response.body);
  }
}
```

## 📦 Project Structure

```
backend/
├── src/
│   ├── config/              # Configuration
│   │   ├── database.ts      # PostgreSQL setup
│   │   └── clerk.ts         # Clerk SDK
│   ├── controllers/         # Request handlers
│   ├── middleware/          # Auth, errors, rate limiting
│   ├── models/              # Database models
│   ├── routes/              # API routes
│   ├── services/            # Business logic
│   ├── types/               # TypeScript types
│   ├── utils/               # Utilities
│   └── index.ts             # Entry point
├── logs/                    # Log files
├── Dockerfile               # Docker config
├── docker-compose.yml       # Multi-container setup
├── package.json
├── tsconfig.json
├── .env.example
├── setup.sh                 # Setup script
└── README.md                # Documentation
```

## 🛠 Development Commands

```bash
# Development
npm run dev              # Start with hot reload

# Build
npm run build            # Compile TypeScript

# Production
npm start                # Run compiled code

# Docker
docker-compose up -d     # Start all services
docker-compose down      # Stop all services
docker-compose logs -f   # View logs
```

## 🔒 Security Features

✅ **Clerk Authentication** - Industry-standard auth, no passwords to manage
✅ **Rate Limiting** - Prevent API abuse
✅ **CORS Protection** - Controlled cross-origin access
✅ **Helmet Security** - Secure HTTP headers
✅ **Transaction Locks** - Prevent race conditions
✅ **Input Validation** - Prevent injection attacks
✅ **Error Logging** - Track all errors

## 🚢 Deployment Options

### 1. Docker (Easiest)
```bash
docker-compose up -d
```

### 2. Cloud Platforms

**Heroku:**
```bash
heroku create betacaller-api
heroku addons:create heroku-postgresql
git push heroku main
```

**Railway:**
- Connect GitHub repo
- Add PostgreSQL database
- Set environment variables
- Deploy automatically

**AWS/GCP/Azure:**
- Use Docker deployment
- Set up managed PostgreSQL
- Configure environment variables
- Set up load balancer

## 📊 Monitoring

- **Logs**: Check `logs/combined.log` and `logs/error.log`
- **Health**: Monitor `/health` endpoint
- **Database**: Check PostgreSQL connection
- **Docker**: `docker-compose ps` for container status

## 🐛 Troubleshooting

### Port already in use
```bash
# Find process using port 3000
lsof -i :3000
# Kill it
kill -9 <PID>
```

### Database connection error
```bash
# Check PostgreSQL is running
psql -U postgres
# Create database
createdb betacaller
```

### Clerk authentication fails
- Check CLERK_SECRET_KEY is correct
- Verify token is being sent in header
- Check Clerk dashboard for errors

### Docker issues
```bash
# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## ✅ Production Checklist

- [ ] Set up Clerk production instance
- [ ] Get Twilio production credentials
- [ ] Set up production PostgreSQL database
- [ ] Update CORS_ORIGIN to production URL
- [ ] Set strong database passwords
- [ ] Enable SSL for database connection
- [ ] Set up monitoring/alerts
- [ ] Configure backup strategy
- [ ] Set up CDN if needed
- [ ] Test all endpoints
- [ ] Load testing
- [ ] Security audit

## 🎓 Next Steps

1. **Set up Clerk** - Get your authentication keys
2. **Configure Twilio** - Set up voice calling
3. **Update Flutter app** - Connect to backend API
4. **Test integration** - Make test calls
5. **Deploy to production** - Choose hosting platform

## 📞 Support

- **Clerk Docs**: https://clerk.com/docs
- **Twilio Docs**: https://www.twilio.com/docs
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Docker**: https://docs.docker.com/

---

**🎉 Your backend is ready! Update the `.env` file and start building!**
