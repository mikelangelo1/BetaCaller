# BetaCaller Backend API

TypeScript-based backend API for BetaCaller VoIP application with Clerk authentication and Twilio integration.

## Features

- **Clerk Authentication** - Secure user authentication with Clerk
- **TypeScript** - Type-safe code with full TypeScript support
- **PostgreSQL** - Robust database with Sequelize ORM
- **Twilio Integration** - VoIP calling with Twilio Voice API
- **Docker Support** - Easy deployment with Docker and Docker Compose
- **Rate Limiting** - API protection with express-rate-limit
- **Logging** - Comprehensive logging with Winston
- **Error Handling** - Centralized error handling

## Tech Stack

- **Runtime**: Node.js 18+
- **Language**: TypeScript 5.x
- **Framework**: Express.js
- **Database**: PostgreSQL with Sequelize ORM
- **Authentication**: Clerk
- **VoIP**: Twilio Voice SDK
- **Logging**: Winston
- **Validation**: Zod

## Prerequisites

- Node.js 18+ and npm
- PostgreSQL 15+
- Clerk account (get your keys from https://clerk.com)
- Twilio account (get your credentials from https://twilio.com)

## Quick Start

### 1. Install Dependencies

\`\`\`bash
npm install
\`\`\`

### 2. Environment Setup

Copy `.env.example` to `.env` and configure:

\`\`\`bash
cp .env.example .env
\`\`\`

Update the following required variables:

\`\`\`env
# Database
DB_PASSWORD=your_postgres_password

# Clerk
CLERK_SECRET_KEY=sk_test_your_clerk_secret_key
CLERK_PUBLISHABLE_KEY=pk_test_your_clerk_publishable_key

# Twilio
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_API_KEY=your_api_key
TWILIO_API_SECRET=your_api_secret
TWILIO_TWIML_APP_SID=your_twiml_app_sid
TWILIO_PHONE_NUMBER=+1234567890
\`\`\`

### 3. Database Setup

Make sure PostgreSQL is running and create the database:

\`\`\`bash
createdb betacaller
\`\`\`

### 4. Run Development Server

\`\`\`bash
npm run dev
\`\`\`

The API will be available at http://localhost:3000

## Docker Deployment

### Build and Run with Docker Compose

\`\`\`bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
\`\`\`

### Build Docker Image Only

\`\`\`bash
docker build -t betacaller-backend .
\`\`\`

## API Endpoints

### Authentication (Clerk)

All authenticated endpoints require `Authorization: Bearer <clerk_token>` header.

#### `GET /api/auth/profile`
Get current user profile

#### `PUT /api/auth/profile`
Update user profile
- **Body**: `{ displayName, phoneNumber }`

#### `DELETE /api/auth/account`
Delete user account

### Balance Management

#### `GET /api/balance`
Get current balance

#### `POST /api/balance/add`
Add balance to account
- **Body**: `{ amount: number }`

#### `GET /api/balance/transactions`
Get transaction history
- **Query**: `?limit=20&offset=0`

### Twilio

#### `GET /api/twilio/token`
Get Twilio access token for making calls

#### `POST /api/twilio/voice`
Twilio voice webhook (called by Twilio)

#### `POST /api/twilio/status`
Twilio call status webhook (called by Twilio)

### Call Management

#### `POST /api/calls`
Create a new call record
- **Body**: `{ phoneNumber, contactName, callType }`

#### `PUT /api/calls/:callId/end`
End a call and calculate cost
- **Body**: `{ duration, twilioCallSid }`

#### `GET /api/calls/history`
Get call history
- **Query**: `?limit=20&offset=0`

#### `GET /api/calls/statistics`
Get call statistics

#### `DELETE /api/calls/:callId`
Delete a call record

### Health Check

#### `GET /health`
Health check endpoint
- Returns server status and uptime

## Scripts

\`\`\`bash
# Development
npm run dev          # Start development server with hot reload

# Build
npm run build        # Compile TypeScript to JavaScript

# Production
npm start            # Run compiled JavaScript

# Code Quality
npm run lint         # Run ESLint
npm run format       # Format code with Prettier

# Testing
npm test             # Run tests (to be implemented)
\`\`\`

## Project Structure

\`\`\`
backend/
├── src/
│   ├── config/           # Configuration files
│   │   ├── database.ts   # Database configuration
│   │   └── clerk.ts      # Clerk configuration
│   ├── controllers/      # Request handlers
│   │   ├── auth.controller.ts
│   │   ├── balance.controller.ts
│   │   ├── call.controller.ts
│   │   └── twilio.controller.ts
│   ├── middleware/       # Express middleware
│   │   ├── clerkAuth.ts  # Clerk authentication
│   │   ├── errorHandler.ts
│   │   └── rateLimiter.ts
│   ├── models/           # Database models
│   │   ├── User.ts
│   │   ├── Transaction.ts
│   │   ├── CallRecord.ts
│   │   └── CallRate.ts
│   ├── routes/           # API routes
│   │   ├── auth.routes.ts
│   │   ├── balance.routes.ts
│   │   ├── call.routes.ts
│   │   ├── twilio.routes.ts
│   │   └── user.routes.ts
│   ├── services/         # Business logic
│   │   ├── balance.service.ts
│   │   ├── call.service.ts
│   │   └── twilio.service.ts
│   ├── types/            # TypeScript types
│   │   └── index.ts
│   ├── utils/            # Utilities
│   │   └── logger.ts
│   └── index.ts          # Application entry point
├── logs/                 # Log files
├── Dockerfile            # Docker configuration
├── docker-compose.yml    # Docker Compose configuration
├── package.json
├── tsconfig.json
└── .env.example
\`\`\`

## Database Models

### User
- clerkId (unique identifier from Clerk)
- email
- phoneNumber
- displayName
- profileImageUrl
- balance
- lastLoginAt
- isActive

### Transaction
- userId
- type (credit/debit)
- amount
- description
- balanceBefore
- balanceAfter
- metadata

### CallRecord
- userId
- phoneNumber
- contactName
- callType (outgoing/incoming/missed)
- callStatus
- duration (seconds)
- cost
- twilioCallSid
- startTime
- endTime

### CallRate
- countryCode
- countryName
- ratePerMinute
- currency
- isActive

## Clerk Integration

This backend uses Clerk for authentication. Users authenticate through the Flutter app using Clerk, and the backend validates the Clerk session token.

### Setup Clerk

1. Create account at https://clerk.com
2. Create a new application
3. Get your Secret Key and Publishable Key
4. Configure allowed origins (CORS)
5. Enable email/phone authentication

## Twilio Integration

### Setup Twilio

1. Create account at https://twilio.com
2. Get Account SID and Auth Token
3. Create API Keys (for generating access tokens)
4. Create a TwiML Application
5. Buy a phone number with Voice capability
6. Configure TwiML app voice webhook: `https://your-api.com/api/twilio/voice`

## Security Features

- **Clerk Authentication** - Industry-standard authentication
- **Rate Limiting** - Prevent abuse
- **Helmet** - Secure HTTP headers
- **CORS** - Controlled cross-origin access
- **Input Validation** - Prevent injection attacks
- **Transaction Locks** - Prevent race conditions in balance updates

## Error Handling

All errors are centralized and logged:
- Validation errors return 400
- Authentication errors return 401
- Server errors return 500
- All errors logged to files and console

## Logging

Winston logger with multiple transports:
- **Console**: Colored, formatted output
- **error.log**: Error-level logs only
- **combined.log**: All logs

## Production Deployment

### Option 1: Docker (Recommended)

\`\`\`bash
docker-compose up -d
\`\`\`

### Option 2: Node.js

\`\`\`bash
npm run build
NODE_ENV=production npm start
\`\`\`

### Environment Variables

Ensure all production environment variables are set:
- Use strong database passwords
- Secure Clerk and Twilio credentials
- Set proper CORS origins
- Configure appropriate rate limits

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

MIT License

## Support

For issues or questions:
- Backend API issues: Create an issue in the repository
- Clerk authentication: https://clerk.com/docs
- Twilio integration: https://www.twilio.com/docs




  Running the Stack:

  # Start services
  docker-compose up -d

  # Stop services
  docker-compose down

  # View logs
  docker-compose logs -f api
  docker-compose logs -f postgres

  # Rebuild after code changes
  docker-compose down && docker-compose build && docker-compose up -d